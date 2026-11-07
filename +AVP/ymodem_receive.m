function files = ymodem_receive(serial_obj, output_dir, start_timeout_s, byte_timeout_s)
	% Minimal YMODEM Receiver (Rollover & sscanf fixes included)
	% serial_obj: configured serialport object (e.g., s = serialport("COM3", 115200))
	% start_timeout_s: seconds to wait for the sender's first header; on expiry returns {}
	%   (a sender with nothing to send may stay silent). Default Inf.
	% byte_timeout_s: once the transfer has started, seconds of silence that abort it with
	%   an error. Default 10.
	% A file whose received length falls short of its header's size is an error.
	if nargin < 3, start_timeout_s = Inf; end
	if nargin < 4, byte_timeout_s = 10; end

	% Protocol Constants
	SOH = 1; STX = 2; EOT = 4; ACK = 6; NAK = 21; C = 67;

	file_open = false;
	bytes_remaining = 0;
	expected_blk = 0; % Track expected block to handle 8-bit rollover
	files = {};
	nak_run = 0; max_naks = 10; % consecutive NAKs before the transfer is abandoned

	% Re-send "C" every 3 s until a header arrives: a sender not yet listening misses
	% the first one. Bytes before the header (console text) are dropped.
	disp('Initiating YMODEM transfer. Sending "C"...');
	t0 = tic; tC = -Inf; header = [];
	while isempty(header)
		if toc(t0) > start_timeout_s
			disp('YMODEM: no sender within the start timeout.');
			return
		end
		if toc(t0) - tC >= 3, write(serial_obj, C, 'uint8'); tC = toc(t0); end
		if serial_obj.NumBytesAvailable
			b = read(serial_obj, 1, 'uint8');
			if b == SOH || b == STX, header = b; end
			if b == EOT % a batch with nothing in it
				write(serial_obj, ACK, 'uint8');
				return
			end
		else
			pause(0.005);
		end
	end

	try
		while true
			% 1. Wait for a header byte (SOH, STX, or EOT); the first was read above
			if isempty(header), header = wait_for_bytes(serial_obj, 1, byte_timeout_s); end

			if header == SOH || header == STX
				% 2. Determine packet size (SOH = 128, STX = 1024)
				len = 128;
				if header == STX, len = 1024; end

				% 3. Read the rest of the packet
				packet = wait_for_bytes(serial_obj, len + 4, byte_timeout_s);
				blk = double(packet(1));
				inv_blk = double(packet(2));
				data = packet(3 : end-2);

				% Extract received CRC
				rx_crc = bitor(bitshift(uint16(packet(end-1)), 8), uint16(packet(end)));

				% --- Verification ---
				if (blk + inv_blk ~= 255) || (calc_crc16(data) ~= rx_crc)
					disp(['Corrupted packet (Block ', num2str(blk), '). Sending NAK...']);
					nak_run = nak_naks(nak_run, max_naks);
					write(serial_obj, NAK, 'uint8');
					header = [];
					continue;
				end

				% --- Sequence Handling ---
				if blk == expected_blk
					nak_run = 0;
					if expected_blk == 0 && ~file_open
						% --- Handle True Block 0 (Header or Null) ---
						if data(1) == 0
							write(serial_obj, ACK, 'uint8');
							disp('YMODEM Session terminated gracefully.');
							break;
						else
							% Parse filename and filesize
							null_idx = find(data == 0);
							filename = char(data(1 : null_idx(1)-1));

							% Grab filesize, ignoring optional date/mode data
							fileinfo_str = char(data(null_idx(1)+1 : null_idx(2)-1));
							filesize = sscanf(fileinfo_str, '%f', 1);

							disp(['Receiving file: ', filename, ' (', num2str(filesize), ' bytes)']);
							fid = fopen([char(output_dir) filesep filename], 'w');
							if fid < 0, error('ymodem_receive:open', 'cannot open %s for writing', filename); end
							file_open = true;
							bytes_remaining = filesize;
							expected_blk = 1; % Next expected block is 1
							files = {files{:},filename};

							write(serial_obj, ACK, 'uint8');
							write(serial_obj, C, 'uint8');
						end
					else
						% --- Handle Standard Data Blocks (Includes Rollover Block 0) ---
						if file_open
							bytes_to_write = min(bytes_remaining, len);
							fwrite(fid, data(1:bytes_to_write), 'uint8');
							bytes_remaining = bytes_remaining - bytes_to_write;
						end

						expected_blk = mod(expected_blk + 1, 256); % Roll over 255 -> 0
						write(serial_obj, ACK, 'uint8');
					end

				elseif blk == mod(expected_blk - 1, 256)
					% Sender missed our ACK and sent a duplicate. ACK it again.
					write(serial_obj, ACK, 'uint8');
				else
					% Out of sync sequence
					disp(['Out of sync. Expected ', num2str(expected_blk), ' got ', num2str(blk)]);
					nak_run = nak_naks(nak_run, max_naks);
					write(serial_obj, NAK, 'uint8');
				end

			elseif header == EOT
				% 4. Handle YMODEM EOT handshake
				write(serial_obj, NAK, 'uint8');     % Reject first EOT
				b = wait_for_bytes(serial_obj, 1, byte_timeout_s); % Wait for second EOT
				while b ~= EOT, b = wait_for_bytes(serial_obj, 1, byte_timeout_s); end
				write(serial_obj, ACK, 'uint8');     % ACK second EOT
				write(serial_obj, C, 'uint8');       % Request next file or Null Block 0

				if file_open
					fclose(fid);
					file_open = false;
					if bytes_remaining > 0
						error('ymodem_receive:short', '%s: %d bytes short of its header size', ...
							files{end}, bytes_remaining);
					end
					expected_blk = 0; % Reset sequence for the next file's Block 0
					disp('File successfully written to disk.');
				end
			end
			header = [];
		end

	catch ME
		% Safe cleanup if user hits Ctrl+C or port errors out
		if file_open, fclose(fid); end
		disp('Transfer interrupted or failed.');
		rethrow(ME);
	end
end

% --- Helper: count one more consecutive NAK; error past the limit ---
function n = nak_naks(n, max_naks)
	n = n + 1;
	if n > max_naks
		error('ymodem_receive:naks', '%d consecutive bad or out-of-sync blocks', max_naks);
	end
end

% --- Helper: Block until N bytes are available; error after timeout_s with no new byte ---
function data = wait_for_bytes(s, num_bytes, timeout_s)
	t = tic; n = s.NumBytesAvailable;
	while n < num_bytes
		pause(0.005);
		if s.NumBytesAvailable > n
			n = s.NumBytesAvailable; t = tic;
		elseif toc(t) > timeout_s
			error('ymodem_receive:timeout', 'no byte from the sender for %g s', timeout_s);
		end
	end
	data = read(s, num_bytes, 'uint8');
end

% --- Helper: Calculate CRC-16-CCITT ---
function crc = calc_crc16(data)
	crc = uint16(0);
	for i = 1:length(data)
		crc = bitxor(crc, bitshift(uint16(data(i)), 8));
		for j = 1:8
			if bitand(crc, 32768)
				crc = bitxor(bitshift(crc, 1), 4129);
			else
				crc = bitshift(crc, 1);
			end
		end
	end
end