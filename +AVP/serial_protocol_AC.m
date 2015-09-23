classdef serial_protocol_AC < AVP.serial_protocol
  %> finds port automatically
  %> goes through all available ports and finds one broadcasting a given
  %> string
  properties
    TimeOfLastResponce = cputime;
    WatchDog
    Port = []
  end
  
  properties(Constant)
    CmdNameLength = 4
  end
  
  methods(Static)
    % convertsd command name and parameter bytes into bytestream with
    % appropriate checksums. Format is 4 byte Name (0-filled if
    % necesssary), its csum and param bytes. total checksumm is calculated
    % by send_cmd_return_status
    function Bytes = cmd2bytes(Name,param_bytes)
      % import
      if nargin < 2, param_bytes = []; end
      Bytes = uint8(zeros(1,AVP.serial_protocol_AC.CmdNameLength+1+numel(param_bytes)));
      Bytes(1:numel(Name)) = Name;
      Bytes(AVP.serial_protocol_AC.CmdNameLength+1) = ...
        mod(sum(Bytes(1:AVP.serial_protocol_AC.CmdNameLength)),256);
      Bytes(AVP.serial_protocol_AC.CmdNameLength+2:end) = param_bytes(:);
    end % cmd2bytes
    
    function Port = FindPort(Code,varargin)
      % we are trying to find available serial port which transmits
      % the code
      Port = [];
      % find all available serial ports
      serialInfo = instrhwinfo('serial');
      for i=1:numel(serialInfo.AvailableSerialPorts)
        % now trying to open and read each of them with very small
        % timeout
        fprintf('Checking port %s...\n',serialInfo.AvailableSerialPorts{i});
        drawnow
        s = serial(serialInfo.AvailableSerialPorts{i},varargin{:});
        try
          fopen(s);
          T1 = cputime + 1; % wait for 3 seconds max
          while cputime < T1
            if s.BytesAvailable >= numel(Code)*2-1, % yes, port is transmitting something
              str = char(fread(s,numel(Code)*2-1)); % make sure that captures string is long
              % enough to contain the whole code
              if ~isempty(strfind(str(:).',Code)) %found port transmitting Code
                % clean receive buffer, so it is not likely to overfloat
                if s.BytesAvailable ~= 0, fread(s,s.BytesAvailable); end
                % sending command NOOP "manually" because object is not here yet
                disp('Found breadcasting port, sending NOOP...');
                fwrite(s,[uint8('NOOP') 60 120]); % NOOP is part of the handshake
                % it causes FW to stopp sending beacon
                % two following bytes are checksums
                Port = serialInfo.AvailableSerialPorts{i};
                % now we have to skip all the beacon stuff until we get
                % NOOP's reply whoch should be 0 byte status 0 16-bit size
                % of data and 0 checksum
                T1 = cputime + 2; % wait for 2 seconds max
                while cputime < T1
                  if s.BytesAvailable ~= 0
                    if fread(s,1,'uint8') == 0, % one byte return status,
                      fread(s,3,'uint8');  % 2 bytes size and 1 byte checksum
                      fclose(s)
                      delete(s)
                      return
                    end
                  end
                end
                Port = [];
                error('Did not get 0 - protocol is broken!');
              end
            end
          end
          fclose(s);
        catch ME
          Port = [];
          disp(['Problem with port ' s.Port]);
          disp(ME.message);
        end
        delete(s);
      end
    end % FindPort
    
  end % static methods
  
  
  methods
    %> finds port which broadcasts code or tries to connect to old one
    %> (because FW stops broadcasting on first connection).
    %> FIXME implement broadcasting restart on disconnect
    %> @param code
    %>   - if string value it is the string broadcasted by FW.
    %>      This function goes through all avaibale ports to find one
    %>      broadcasting string "code"
    %>   - if numerical value, it is the port number to connect to
    %>
    function a = serial_protocol_AC(code,varargin)
      if isstr(code)
        global OldPort
        Port = AVP.serial_protocol_AC.FindPort(code,varargin{:});
        if isempty(Port)
          try
            eval(['Port = OldPort.Code_' code ';']);
            disp(['Trying previous port <' Port '>...'])
          catch
            error(['Can not find port that transmits <', code '>!']),
          end
        else
          eval(['OldPort.Code_' code ' = Port;']);
        end
      else
        Port = ['COM' num2str(code)];
      end
      a = a@AVP.serial_protocol(Port,varargin{:});
    end % constructor

    function send_command_AC(a,Name,param_bytes)
      if nargin < 3, param_bytes = []; end
      a.send_command(...
        AVP.serial_protocol_AC.cmd2bytes(Name,param_bytes));
    end % send_command
    
    function data = send_cmd_return_data_AC(a,Name,param_bytes)
      if nargin < 3, param_bytes = []; end
      data = a.send_cmd_return_data(...
        AVP.serial_protocol_AC.cmd2bytes(Name,param_bytes));
    end % send_cmd_return_data
    
    
  end % methods
end % serial_protocol_AC

