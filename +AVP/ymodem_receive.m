function ymodem_receive(serial_obj, output_dir)
	% Minimal YMODEM Receiver (Rollover & sscanf fixes included)
	% serial_obj: configured serialport object (e.g., s = serialport("COM3", 115200))

	% Protocol Constants
	SOH = 1; STX = 2; EOT = 4; ACK = 6; NAK = 21; C = 67;

	disp('Initiating YMODEM transfer. Sending "C"...');
	write(serial_obj, C, 'uint8');

	file_open = false;
	bytes_remaining = 0;
	expected_blk = 0; % Track expected block to handle 8-bit rollover

	try
		while true
			% 1. Wait for a header byte (SOH, STX, or EOT)
			header = wait_for_bytes(serial_obj, 1);

			if header == SOH || header == STX
				% 2. Determine packet size (SOH = 128, STX = 1024)
				len = 128;
				if header == STX, len = 1024; end

				% 3. Read the rest of the packet
				packet = wait_for_bytes(serial_obj, len + 4);
				blk = packet(1);
				inv_blk = packet(2);
				data = packet(3 : end-2);

				% Extract received CRC
				rx_crc = bitor(bitshift(uint16(packet(end-1)), 8), uint16(packet(end)));

				% --- Verification ---
				if (blk + inv_blk ~= 255) || (calc_crc16(data) ~= rx_crc)
					disp(['Corrupted packet (Block ', num2str(blk), '). Sending NAK...']);
					write(serial_obj, NAK, 'uint8');
					continue;
				end

				% --- Sequence Handling ---
				if blk == expected_blk
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
							fid = fopen([output_dir filesep filename], 'w');
							file_open = true;
							bytes_remaining = filesize;
							expected_blk = 1; % Next expected block is 1

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
					write(serial_obj, NAK, 'uint8');
				end

			elseif header == EOT
				% 4. Handle YMODEM EOT handshake
				write(serial_obj, NAK, 'uint8');     % Reject first EOT
				wait_for_bytes(serial_obj, 1);       % Wait for second EOT
				write(serial_obj, ACK, 'uint8');     % ACK second EOT
				write(serial_obj, C, 'uint8');       % Request next file or Null Block 0

				if file_open
					fclose(fid);
					file_open = false;
					expected_blk = 0; % Reset sequence for the next file's Block 0
					disp('File successfully written to disk.');
				end
			end
		end

	catch ME
		% Safe cleanup if user hits Ctrl+C or port errors out
		if file_open, fclose(fid); end
		disp('Transfer interrupted or failed.');
		rethrow(ME);
	end
end

% --- Helper: Block until N bytes are available ---
function data = wait_for_bytes(s, num_bytes)
	while s.NumBytesAvailable < num_bytes
		pause(0.005);
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