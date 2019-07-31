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
    
    function status = CheckPort(Port,Code,varargin)
      fprintf('Checking port %s...\n',Port);
      s = serial(Port,varargin{:});
      try
        fopen(s);
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
              fclose(s)
              delete(s)
              return
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
      status = false;
    end
  end % static methods
  
  methods
    %> finds port which broadcasts code or tries to connect to old one
    %> (because FW stops transmitting on first connection).
    %> FIXME implement transmitting restart on disconnect
    %> @param code
    %>   - if string value it is the string broadcasted by FW.
    %>      This function goes through all avaibale ports to find one
    %>      transmitting string "code"
    %>   - if numerical value, it is the port number to connect to
    %> @param varargin is passed to serial() constructor
    function a = serial_protocol_AC(code,varargin)
      if isstr(code)
        serialInfo = instrhwinfo('serial');
        AvailPorts = serialInfo.AvailableSerialPorts;
        
        global OldPorts %!< keeps information for different codes
        if ~isempty(OldPorts) && isfield(OldPorts,['Code_' code])
          OldPort = getfield(OldPorts,['Code_' code]);
          if any(strcmp(AvailPorts,OldPort))
            try
              disp('Trying old port first...')
              s = serial(OldPort,varargin{:});
              fopen(s);
              if AVP.serial_protocol_AC.PingNOOP(s), Port = OldPort; end
            catch ME
              disp(['OldPort ' s.Port ' does not work:']);
              disp(ME.message);
            end
            fclose(s)
            delete(s)
          end
        end
        
        
        % looking through all available ports
        if ~exist('Port','var')
          for i=1:numel(AvailPorts)
            % now trying to open and read each of them with very small
            % timeout
            if AVP.serial_protocol_AC.CheckPort(AvailPorts{i},code,varargin{:})
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

