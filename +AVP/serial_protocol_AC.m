classdef serial_protocol_AC < AVP.serial_protocol
  % finds port automatically
  % goes through all available ports and tries to open them, sends Query
  % command to those which open and verifies returned Info
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
        s = serial(serialInfo.AvailableSerialPorts{i},varargin{:});
        try
          fopen(s);
          pause(0.1); % to accumulate some bytes
          if s.BytesAvailable >= numel(Code)*2-1, % yes, port is transmitting something
            str = char(fread(s,numel(Code)*2-1));
            if ~isempty(strfind(str(:).',Code)) %found 2Xj
              % sending command NOOP "manually" because object is not here yet
              fwrite(s,[uint8('NOOP') 60 120]); % to stop broadcasting
              Port = serialInfo.AvailableSerialPorts{i};
              % now we have to skip all the beacon stuff until we get NOOP
              % reply
              T1 = cputime + 2; % wait for 1 second max
              while cputime < T1
                if s.BytesAvailable ~= 0
                  if fread(s,1,'uint8') == 0,
                    fread(s,2,'uint8'); % 16 bit return status/size and a checksum
                    break;
                  end
                end
              end
              if cputime >= T1, error('Did not get 0!'); end
            end
          end
          fclose(s);
        catch ME
          disp(['Problem with port ' s.Port]);
          disp(ME.message);
        end
        delete(s);
      end
    end % FindPort
    
  end % static methods
  
  
  methods
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
    
    
    function a = serial_protocol_AC(code,varargin)
      % finds port which broadcasts code or tries to connect to old one
      % (because FW stops broadcasting on first connection).
      % FIXME implement broadcasting restart on disconnect
      global OldPort
      Port = AVP.serial_protocol_AC.FindPort(code,varargin{:});
      if isempty(Port)
        if exist('OldPort') && ~isempty(OldPort)
          Port = OldPort;
        else
          error(['Can not find port that transmits <', code '>!']),
        end
      else
        OldPort = Port;
      end
      a = a@AVP.serial_protocol(Port,varargin{:});
    end % constructor
  end % methods
end % serial_protocol_AC

