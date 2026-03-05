classdef serial_protocol_AC < AVP.serial_protocol
	%> finds port automatically
	%> goes through all available ports and finds one transmitting a given
	%> string
	properties
		TimeOfLastResponce = cputime;
		WatchDog
		Port = []
	end

	methods(Static)
		function status = PingNOOP(s)
			disp('Sending NOOP...');
			fwrite(s,0,'uint8'); % NOOP is part of the handshake
			% it causes FW to stop sending beacon.
			% now we have to skip all the beacon stuff until we get
			% NOOP's reply whoch should be 0 byte status 0 16-bit size
			% of data and 0 checksum
			start = tic;
			while toc(start) < 1
				if s.BytesAvailable >= 4
					if fread(s,1,'uint8') == 0, % possible skipping remaining broadcast
						fread(s,3,'uint8');  % 2 bytes size and 1 byte checksum
						status = true;
						return
					end
				end
			end
			error('Did not get 0 - protocol is broken!');
			status = false;
		end

		function status = CheckPort(Port,Code,BaudRate,varargin)
			fprintf('Checking port %s...\n',Port);
			try
				s = serialport(Port,BaudRate,varargin{:});
				start = tic; % timeout
				while toc(start) < 0.5
					if s.BytesAvailable >= numel(Code)*2-1, % yes, port is transmitting something
						str = char(fread(s,numel(Code)*2-1)); % make sure that captures string is long
						% enough to contain the whole code
						fprintf(1,'Port is transmitting "%s"...\n',str);
						if ~isempty(strfind(str(:).',Code)) %found port transmitting Code
							% clean receive buffer, so it is not likely to overfloat
							if s.BytesAvailable ~= 0, fread(s,s.BytesAvailable); end
							% sending command NOOP "manually" because object is not here yet
							disp('Found transmitting port...');
							status = AVP.serial_protocol_AC.PingNOOP(s);
							clear s
							return
						end
					end
				end
			catch ME
				Port = [];
				warning(ME.message);
				disp(['Problem with port ' Port]);
			end
			status = false;
		end % CheckPort
	end % static methods

	methods
		function a = serial_protocol_AC(code,varargin)
			%> finds port which broadcasts code or tries to connect to old one
			%> (because FW stops transmitting on first connection).
			%> FIXME implement transmitting restart on disconnect
			%> @param code
			%>   - if string value it is the string broadcasted by FW.
			%>      This function goes through all avaibale ports to find one
			%>      transmitting string "code"
			%>   - if numerical value, it is the port number to connect to
			%> @param varargin is passed to serialport() constructor
			%>   - Type: what comports return in 'type' field
			%>   - name: what comports return in 'name' field
			%>   - BaudRate:

			AVP.opt_param('BaudRate',115200,1);

			if isstr(code) % port is identified by the broadcasted code
				ports = AVP.comports();
				if isempty(ports)
					error('Can not find any COM port');
				end
				AVP.opt_param('Type','',1);
				if ~isempty(Type)
					ports = ports(strcmp({ports.type},Type));
					if isempty(ports)
						error(['No ports of type ' Type]);
					end
				end
				AVP.opt_param('name','',1);
				if ~isempty(name)
					ports = ports(strcmp({ports.name},name));
					if isempty(ports)
						error(['No ports with name "' name '"']);
					end
				end

				AvailPorts = {ports.port};

				global OldPorts %>< keeps information for different codes
				if ~isempty(OldPorts) && isfield(OldPorts,['Code_' code])
					OldPort = getfield(OldPorts,['Code_' code]);
					if any(strcmp(AvailPorts,OldPort))
						try
							disp('Trying old port first...')
							s = serialportfind(Port=OldPort);
							if ~isempty(s)
								s.flush
							else
								s = serialport(OldPort,BaudRate);
							end
							if AVP.serial_protocol_AC.PingNOOP(s), Port = OldPort; end
						catch ME
							warning(ME.message);
							disp(['OldPort "' OldPort '" does not work:']);
						end
						clear s
					end
				end


				% looking through all available ports
				if ~exist('Port','var')
					for i=1:numel(AvailPorts)
						% now trying to open and read each of them with very small
						% timeout
						if AVP.serial_protocol_AC.CheckPort(AvailPorts{i},code,...
								BaudRate,varargin{:})
							Port = AvailPorts{i};
							break;
						end
						drawnow
					end
				end
			else % code is a number, so it is specifying port directly
				Port = ['COM' num2str(code)];
			end
			if ~exist('Port','var')
				error('Can not find transmitting port ...')
			end
			a = a@AVP.serial_protocol(Port,varargin{:});
			OldPorts = setfield(OldPorts,['Code_' code],Port);
		end % constructor
	end % methods
end % serial_protocol_AC

