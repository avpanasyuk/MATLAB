classdef serial_protocol < handle
  %   @see Firmware/AVP_LIBS/General/Protocol.h
  properties(SetAccess=protected, GetAccess=public)
    s % serial port object
    command_lock = 0; % prevents comamnds sent from timer routine to interfere
    % the lock is set and checked by send_cmd_wait_result and has to be
    % released in higher level commands or user code after all command
    % return is received
  end
  properties(Constant=true)
    prec = AVP.get_prec;
    SpecErrorCodes = {'Bad checksum','UART overrun'} % defined in AVP_LIB/General/Protocol.h
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
      flush_port(a.s,1)
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
    
    function error_message = send_cmd_return_status(a,cmd_bytes)
      %> This is the lowest level SEND_COMMAND. Reads and displays info
      %> messages. Read end return error messages. Does not read returned
      %> data, not even size word
      %> BECAUSE IT DOES NOT READ ALL OUTPUT IT DOES NOT DO UNLOCK_COMMANDS
      %> WHEN COMMAND SUCCEDES
      %> @param cmd_bytes is array containing both command byte and parameters bytes
      %> @retval message - if empty command succedded. If not - error message
      a.lock_commands
      % command can contain negative arguments, but we have to pass them
      % as uint8. MATLAB cast is totally screwy
      if ~isa(cmd_bytes,'uint8')
        neg = find(cmd_bytes(2:end) < 0) + 1;
        cmd_bytes(neg) = 256 + cmd_bytes(neg);
        cmd_bytes = uint8(cmd_bytes); % now we can convert everything to uint8
      end
      sent_cs = mod(sum(cmd_bytes(:)),256);
      while 1 % loop until FW perorts that it received the command
        fwrite(a.s,[cmd_bytes(:);sent_cs],'uint8');
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
    
    function [code output] = send_cmd_return_output(a,cmd_bytes)
      %> LOW LEVEL send_command, Displays info messages and gets output but
      %> does not process command errors.
      %> This function does UNLOCK_COMMANDS in all cases
      %> @param cmd_bytes is an array containing both command and parameters bytes
      %> @retval code: 0 if success, 1 if failure
      %> @retval output data: data bytes if success, error message if failure
      output = a.send_cmd_return_status(cmd_bytes);
      if isempty(output) % command succeded
        code = 0;
        % reading output
        size = a.wait_and_read(1,'uint16');
        if size ~= 0
          output = uint8(a.wait_and_read(size,'uint8'));
        else output = []; end
        rcvd_csum = a.wait_and_read(1,'uint8');
        a.unlock_commands
        
        output_cs = mod(sum([0; output]),256);
        if output_cs ~= rcvd_csum
          error('Received CS %hu ~= calculated CS %hu!',rcvd_csum,output_cs);
        end
      else
        code = 1;
      end
    end % send_cmd_return_output
    
    function data = send_command(a,ID,cmd_bytes)
      %> handles error condition by issuing error
      %> @retval data - retuned bytes
      if ~exist('cmd_bytes','var'), cmd_bytes = []; end
      if isstr(ID)
        cmd_bytes = [uint8(ID),cmd_bytes(:).'];
      else
        cmd_bytes = [ID,cmd_bytes(:).'];
      end
      [err_code data] = a.send_cmd_return_output(cmd_bytes);
      if err_code ~= 0,
        error('send_command:Command_failed',data);
      end
    end % send_command
  end % methods
  methods(Static)
    function flush_port(s, timeout)
      null_array = zeros(10,1);
      start = cputime();
      while cputime() < start + timeout;
        fwrite(s,null_array);
        pause(timeout/10)
        if s.BytesAvailable > 4 % 4 zeros is the NOOP response
          out = fread(s);
          if ~any(out(end-3:end)), return; end
        end
      end
      error('Flushing timed out!') 
    end % flush_port
  end % static methods
end % serial_protocol

