classdef serial_protocol < handle
	%   @see Firmware/AVP_LIBS/General/Protocol.h
	properties(SetAccess=protected, GetAccess=public)
		s % serial port object
		command_lock = false % prevents comamnds sent from timer routine to interfere
		% the lock is set and checked by send_cmd_wait_result and has to be
		% released in higher level commands or user code after all command
		% return is received
		prev_command = struct('output_size',0,'ID',[]);
	end
	properties(Constant=true)
		prec = AVP.get_prec;
		SpecErrorCodes = {'Bad checksum','UART overrun'} % defined in AVP_LIB/General/Protocol.h
	end
	methods(Access=protected)
		function wait_for_serial(a,N)
			% standard serial timeout may not allow USB to send/receive, so let's
			% do it "manually"
			start = tic();
			while a.s.NumBytesAvailable < N
				if ~a.port_status, error('wait_for_serial:COM_died','Oops!'); end
				if toc(start) > a.s.Timeout
					error('serial_protocol:wait_for_serial:Timeout',...
						['waited for %d bytes, available %d bytes!'],...
						N,a.s.NumBytesAvailable);
				end
				% pause for wire-time of the bytes we still need, floored at 1 ms
				% (MATLAB pause granularity). Yields CPU and processes events.
				pause(max((N - a.s.NumBytesAvailable) * 10 / a.s.BaudRate, 0.001));
			end
		end % wait_for_serial

		function out = wait_and_read_bytes(a,size)
			if nargin < 2, size = 1; end
			a.wait_for_serial(size);
			out = uint8(read(a.s,size,'uint8'));
		end

		% precision may be either type of element in byte (in which case bytes
		% are returned)or type name defined in get_size_of_type
		% @retval Match legacy read: values as double (same types as before).
		function out = wait_and_read(a,size,precision)
			if size == 0, out = []; return; end
			a.wait_for_serial(prod(size)*a.prec.(precision));
			n = prod(size);
			out = double(read(a.s,n,precision));
			if ~isscalar(size)
				out = reshape(out, size);
			end
		end % wait_and_read

		function lock_commands(a)
			if a.command_lock,
				error('lock_commands:Locked',...
					'Another command is being executed!');
			end
			a.check_messages
			a.command_lock = true;
		end

		function check_messages(a)
			if ~a.port_status || a.command_lock, return; end
			while a.s.NumBytesAvailable ~= 0,
				size = read(a.s,1,'uint8');
				Message = a.receive_message(double(size));

				if strncmp(Message,'Error',5),
					error('check_messages:ErrStatus','%s',Message);
				else
					fprintf(1,'%s',Message);
				end
			end
		end % check_messages

		function Message = receive_message(a,size)
			% reads size bytes as string and follwoing byte as a checksum and
			% checks. Verifies that message is ASCII
			Message  = char(a.wait_and_read(size,'uint8').');
			if mod(sum(Message),256) ~= a.wait_and_read(1,'uint8')
				error('receive_message:checksum','Checksum is wrong in message %s!', Message);
			end

			if ~isempty(find(Message < 9 | Message > 126,1)), % not ASCII
				error('receive_message:ProtocolError','Received binary stream <%s> instead of ASCII!',Message);
			end
		end % receive_message

		function check_cs_and_unlock(a,output)
			%> reads next byte in incoming stream as checksum, checks it vs output,
			%> unlocks commands
			%> @param output - array to checksum
			rcvd_csum = a.wait_and_read(1,'uint8');
			a.unlock_commands

			output_cs = mod(sum([0; output(:)]),256);
			if output_cs ~= rcvd_csum
				error('check_cs_and_unlock:checksum','Received CS %hu ~= calculated CS %hu!',rcvd_csum,output_cs);
			end
		end % check_cs_and_unlock

		function data = send_new_command(a,cmd_bytes,no_block)
			err_msg = a.send_cmd_return_status(cmd_bytes);
			if isempty(err_msg) % command succeeded
				size = a.wait_and_read(1,'uint16');
				if size == 0, data = [];
				else
					if no_block
						data = [];
						a.prev_command.output_size = size;
						return
					else
						data = a.wait_and_read_bytes(size);
					end
				end
				a.check_cs_and_unlock(data);
			else
				error('send_new_command:failed','Command failed, %s.',err_msg);
			end
		end % send_new_command

		function [old_output, new_output] = read_old_ouput_and_send_new_command(a,cmd_bytes,no_block)
			old_output = a.wait_and_read_bytes(a.prev_command.output_size);
			a.prev_command.output_size = 0;
			a.check_cs_and_unlock(old_output); % check CS anyway
			new_output = a.send_new_command(cmd_bytes,no_block);
		end % read_old_ouput_and_send_new_command

	end % protected methods
	methods
		%% STRUCTORS
		function a = serial_protocol(comPort,varargin)
			AVP.opt_param('BaudRate',115200,1);
			persistent s
			if ~isstruct(s), s = struct(); end
			if ~isfield(s, comPort) || isempty(s.(comPort)) || ~isvalid(s.(comPort))
				s.(comPort) = serialport(comPort,BaudRate,varargin{:});
			end
			a.s = s.(comPort);
		end

		function delete(a)
			delete(a.s)
			disp('serial port is closed');
		end % delete

		function out = port_status(a)
			out = isa(a.s,'internal.Serialport') && ...
				isvalid(a.s) && ...
				strcmpi(get(a.s,'Status'),'open');
			if out
				try
					a.s.NumBytesAvailable;  %#ok<VUNUS> probe transport - throws if it died
				catch
					out = false;
				end
			end
		end % function port_status

		function disp(a) % display
			if port_status(a)
				disp(['object connected to ' char(a.s.Port) ' port']);
				disp(a.s)
			else
				disp('object connected to an invalid serial port');
				disp('Please delete the object');
				disp(' ');
			end
		end

		function unlock_commands(a)
			a.command_lock = false;
			a.check_messages
		end

		% read and discard everything from the serial port
		function flush(a)
			AVP.serial_protocol.flush_port(a.s)
			a.prev_command.output_size = 0;
			a.unlock_commands
		end

		%% COMMANDS basic functions
		function error_message = send_cmd_return_status(a,cmd_bytes)
			%> This is the lowest level SEND_COMMAND. Reads and displays info
			%> messages. Read end return error messages. Does not read returned
			%> data, not even size word
			%> BECAUSE IT DOES NOT READ ALL OUTPUT IT DOES NOT CHECK CS OR UNLOCK_COMMANDS
			%> WHEN COMMAND SUCCEDES
			%> @param cmd_bytes: both command ID followed by parameter bytes
			%     if numeric vector it will be cast to uint8 vector
			%>    if cell array each element will be typecast to uint8 vector
			%> @retval error_message - if empty command succedded. If not - error message
			a.lock_commands
			% command can contain negative arguments, but we have to pass them
			% as uint8. MATLAB cast is totally screwy
			if iscell(cmd_bytes)
				cmd_id = uint8(cmd_bytes{1});
				cmd_bytes = cellfun(@(x) typecast(x,'uint8'), cmd_bytes(2:end),'UniformOutput',false);
				cmd_bytes = [cmd_id(:).', cmd_bytes{:}];
			else
				if ~isa(cmd_bytes,'uint8')
					neg = find(cmd_bytes(2:end) < 0) + 1;
					cmd_bytes(neg) = 256 + cmd_bytes(neg);
					cmd_bytes = uint8(cmd_bytes); % now we can convert everything to uint8
				end
			end
			sent_cs = mod(sum(cmd_bytes(:)),256);
			% first_try = true;
			while 1 % loop until FW reports that it successfully received the command
				try
					write(a.s,[cmd_bytes(:);sent_cs],'uint8');
				catch ME
					warning(ME.message);
					error('Communication broke!');
				end
				while 1 % loop processing all info_messages until status is returned
					code = a.wait_and_read(1,'int8');
					if code > 0 % it is just an info message, print and keep checking for return
						fprintf(1,'%s',a.receive_message(code));
					else
						if code == 0, error_message = ''; return; end % command succeedded
						if code < -numel(a.SpecErrorCodes) % command was received and failed
							error_message = a.receive_message(-code);
							a.unlock_commands
							return;
						else
							% a special return codes indicating that command was not
							% properly received
							a.wait_and_read(1,'uint8'); % checksum
							fprintf(1,'Reception failed due to %s, retransmitting command...\n', ...
								a.SpecErrorCodes{-code});
							a.flush
						end
					end
				end
			end
		end % send_cmd_return_status


		function output = send_command(a,ID,cmd_bytes,no_block)
			%> @detail handles error condition by issuing error. Handles blocking and
			%> non-blocking commands
			%> @param ID -  coomand ID,  may be uint8 or string.
			%> @param cmd_bytes: if numeric vector it will be cast to uint8 vector
			%>    if cell array each element will be typecast to uint8 vector
			%> @param no_block logical
			%>    - if true command processing never waits for a serial port
			%>    it returns immideatly with output of the previous command, if
			%>    it is the same command and all bytes are already available in port
			%>    buffer
			%>    - if false we send command and wait in drawnow loop until all
			%>    expected return data arrive
			%> @retval output - returned bytes
			no_block = exist('no_block','var') && ~isempty(no_block) && no_block;

			if ~exist('cmd_bytes','var'), cmd_bytes = []; end
			if isstring(ID), ID = char(ID); end
			if iscell(cmd_bytes)
				cmd_bytes = {ID, cmd_bytes{:}};
			else
				if ischar(ID)
					cmd_bytes = [uint8(ID),cmd_bytes(:).'];
				else
					cmd_bytes = [ID,cmd_bytes(:).'];
				end
			end

			if a.prev_command.output_size == 0 % we are not waiting for prevous command output
				output = a.send_new_command(cmd_bytes,no_block);
			else
				needed = a.prev_command.output_size + 1 - a.s.NumBytesAvailable; % plus CS
				if needed > 0
					pause(max(needed * 10 / a.s.BaudRate, 0.001));
				end
				if a.s.NumBytesAvailable < a.prev_command.output_size + 1 % plus CS
					% still not all prevous command output arrived
					if no_block % drop current command - we have nothing else to do
						output = [];
					else % block until previous command output  is wholly read
						% we were non_blocking but now we block, so we discard previous
						% command return
						[~, output] = a.read_old_ouput_and_send_new_command(cmd_bytes,false);
					end
				else % we got an old output in the buffer
					[old_output, output] = a.read_old_ouput_and_send_new_command(cmd_bytes,no_block);
					if no_block
						if strcmp(ID,a.prev_command.ID) % different command
							output = old_output; % if it is the same command we return output from
							% the old command instead, new output should be empty anyway
						end
						a.prev_command.ID = ID;
					end
				end
			end
		end % send_command
	end % public methods
	methods(Static,Access=protected)
		function flush_port(s)
			start = tic();
			for k=0:7
				write(s,zeros(2^k,1),'uint8');
				pause(s.Timeout/20)
				if s.NumBytesAvailable >= 4 % 4 zeros is the NOOP response
					str = uint8(read(s,3,'uint8'));
					for c=1:s.NumBytesAvailable
						str = [str(:); uint8(read(s,1,'uint8'))];
						if all(str(end-3:end) == 0) % found NOOP
							return;
						end
					end
				end
				if toc(start) > s.Timeout, break; end
			end
			error('flush_port:timeout','Flushing timed out!')
		end % flush_port
	end % static methods
end % serial_protocol

