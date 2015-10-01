classdef serial_protocol < handle
  %   * @verbatim    Protocol description.
%     - all GUI->FW messages are commands:
%       - 4 bytes ASCII command name
%       - 1 byte its checksum,
%       - serial_protocol::Command::NumParamBytes bytes of parameters
%       - 1 byte of total checksum,
%     - FW-GUI messages are differentiated  based on the first int8_t CODE
%         - command return:
%           - If CODE is 0 the following is successful latest command return:
%             - uint16_t Size is size of data being transmitted.
%             - data
%             - 1 uint8_t data checksum
%           - If CODE is < 0, then it is the last command failure return message:
%             - CODE > -NUM_SPEC_CODES, @see enum SpecErrorCodes
% enum SpecErrorCodes { CMD_NAME_CS=1, CMD_MESSAGE_CS, UART_OVERRUN, NUM_SPEC_CODES };
%            - if CODE <= -NUM_SPEC_CODES it is the error message size, followed by
%               - error message text without trailing 0
%               - 1 uint8_t error message text checksum
%               .
%         Every command has to be responded with either successful return or error message, and only
%         one of them.
%         - If CODE is > 0, then it is an info message size, followed by
%           - info message text without trailing 0
%           - 1 uint8_t info message text checksum
%           .
%         Info messages may come at any time
%       If error or info message do not fit into 127 bytes remaining text is formatted into consequtive  info message(s) is
  %   * @endverbatim
  properties(SetAccess=protected, GetAccess=public)
    s % serial port object
    command_lock = 0; % prevents comamnds sent from timer routine to interfere
    % the lock is set and checked by send_cmd_wait_result and has to be
    % released in higher level commands or user code after all command
    % return is received
  end
  properties(Constant=true)
    prec = AVP.get_size_of_type;
    SpecErrorCodes = {'NOOP','Wrong command ID','Bad checksum','UART overrun'} % defined in AVP_LIB/General/Protocol.h
  end
  methods
    %% STRUCTORS
    function a = serial_protocol(comPort,varargin)
      a.s=serial(comPort,varargin{:});
      fopen(a.s);
      if ~a.port_status, error('Can not open com port!'); end
      % a.flush
    end
    
    function delete(a)
      a.flush
      fclose(a.s);
      delete(a.s);
      disp('serial port is closed');
    end % delete
    
    function out = port_status(a)
      out = isa(a.s,'serial') && isvalid(a.s) && strcmpi(get(a.s,'Status'),'open');
    end % function port_status
    
    function disp(a) % display
      if port_status(a),
        disp(['object connected to ' get(a.s,'port') ' port']);
        disp(a.s)
      else
        disp('object connected to an invalid serial port');
        disp('Please delete the object');
        disp(' ');
      end
    end
    
    % read and discard everything from the serial port
    function flush(a)
      while 1
        pause(0.01)
        n = get(a.s,'BytesAvailable');
        if n ~= 0, fread(a.s,n); else break; end
      end
    end
    
    function reset(a)
      a.flush
      a.unlock_commands
    end
    
    %% COMMANDS basic functions
    function lock_commands(a)
      if a.command_lock,
        error('protocol:command_locked',...
          'Another command is being executed!');
      end
      a.check_messages
      a.command_lock = 1;
    end
    
    function unlock_commands(a)
      a.command_lock = 0;
      a.check_messages
    end
    
    function wait_for_serial(a,N)
      % standard serial timeout may not allow USB to send/receive, so let's
      % do it "manually"
      start = cputime();
      while get(a.s,'BytesAvailable') < N
        if ~a.port_status, error('wait_for_serial:COM_died','Oops!'); end
        if cputime() - start > get(a.s,'Timeout')
          a.flush
          % dbstack
          % a.close_serial;
          error('serial_protocol:wait_for_serial:Timeout',...
            ['waited for %d bytes, available %d bytes!'],...
            N,get(a.s,'BytesAvailable'));
        end
        drawnow % to allow sending and receiving to complete
      end
    end
    
    function out = wait_and_read_bytes(a,size)
      if nargin < 2, size = 1; end
      a.wait_for_serial(size);
      out = uint8(fread(a.s,size,'uint8')); % idiosy! serial::fread always
      % returns double
    end
    
    % precision may be either type of element in byte (in which case bytes
    % are returned)or type name defined in get_size_of_type
    % @retval idiosy! serial::fread always returns double, does not matter
    % what precision is specified. SO THIS FUNCTION ALWAYS RETURNS DOUBLES
    function out = wait_and_read(a,size,precision)
      if size == 0, out = []; return; end
      a.wait_for_serial(prod(size)*a.prec.(precision));
      out = fread(a.s,size,precision);
    end % wait_and_read
    
    function Message = receive_message(a,size)
      % reads size bytes as string and follwoing byte as a checksum and
      % checks. Verifies that message is ASCII
      Message  = char(a.wait_and_read(size,'uint8').');
      if mod(sum(Message),256) ~= a.wait_and_read(1,'uint8')
        error('Checksum is wrong in message %s!', Message);
      end
      
      if ~isempty(find(Message < 9 | Message > 126,1)), % not ASCII
        error('ProtocolError: Received binary stream <%s> instead of ASCII!',Message);
      end
    end
    
    %%%%%%%%%%
    % CHECK_MESSAGE - checks for info messages teensy may send from time to time
    % should not be called when data are expected
    % If message starts with "Error" error is issued
    function check_messages(a)
      if ~a.port_status || a.command_lock, return; end
      while get(a.s,'BytesAvailable') ~= 0,
        size = fread(a.s,1,'uint8');
        Message = a.receive_message(size);
        
        if strncmp(Message,'Error',5),
          error([place ':ErrStatus'],'%s',Message);
        else % fprintf(1,[place ': ' MessageBytes]);
          fprintf(1,'%s',Message);
        end
      end
    end % check_messages
    
    function [err_code, output] = send_cmd_return_output(a,cmd_bytes)
      %> This is the lowest level SEND_COMMAND. Sorts output but not handles
      %> it in any way. Displays info messages
      %> @param cmd_bytes is array containing both command byte and parameters bytes
      %> @retval err_code: 0 if success, 1 if failure
      %> @retval output data: data bytes if success, error message if failure
      a.lock_commands
      % command can contain negative arguments, but we have to pass them
      % as uint8. MATLAB cast is totally screwy
      if ~isa(cmd_bytes,'uint8')
        neg = find(cmd_bytes(2:end) < 0) + 1;
        cmd_bytes(neg) = 256 + cmd_bytes(neg);
        cmd_bytes = uint8(cmd_bytes); % now we can convert everything to uint8
      end
      sent_cs = mod(sum(cmd_bytes(:)),256);
      command_acq = false; % check whether command was successfully received
      while ~command_acq
        fwrite(a.s,[cmd_bytes(:);sent_cs],'uint8');
        err_code  = -1; % "not defined " value
        while err_code < 0 % loop processing all info_messages until err_code is assigned
          message_code = a.wait_and_read(1,'int8');
          
          if message_code == 0 % status ok, return data (if any) are following
            err_code = 0;
            command_acq = true;
            size = a.wait_and_read(1,'uint16');
            if size ~= 0
              output = uint8(a.wait_and_read(size,'uint8'));
            else output = []; end
            rcvd_csum = a.wait_and_read(1,'uint8');
            
            output_cs = mod(sum([0; output]),256);
            if output_cs ~= rcvd_csum
              error('Received CS %hu ~= calculated CS %hu!',rcvd_csum,output_cs);
            end
          else
            if message_code > 0 % it is just an info message, stay in while cycle
              fprintf(1,'%s',a.receive_message(message_code));
            else % unsuccess
              err_code = 1;
              % check return codes
              if message_code < -3, % command was received, but failed.  
                output = a.receive_message(-message_code);
                command_acq = true;
              else % problem with communication. Those are 
                % a special return codes, defined in AVP_LIB/General/Protocol.h
                fprintf(1,'Reception failed due to %s, retransmitting command...\n', ...
                  a.SpecErrorCodes{-message_code});
                a.flush
              end
            end
          end
        end
      end
      a.unlock_commands
    end % send_cmd_return_output
    
    function data = send_cmd_return_data(a,cmd_bytes)
      % handles error condition by issuing error
      [err_code data] = a.send_cmd_return_output(cmd_bytes);
      if err_code ~= 0,
        error('Command failed due to <%s>', data);
      end
    end % send_cmd_return_data
    
    function send_command(a,cmd_bytes)
      % @brief the simplest COMMAND, does not except any return data.
      % @param cmd_bytes is array containing both command ID and parameters bytes
      data = a.send_cmd_return_data(cmd_bytes);
      if ~isempty(data)
        error('There should be no returned data!');
      end
    end % send_command
  end % methods
end % serial_protocol

