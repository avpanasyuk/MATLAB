classdef DT9602R < handle
  properties
    s % serial port
  end
  properties(Constant)
    frame_size = 14
    num_frames = 5 % I combine 3 extrapolations over sliding groups of 3
    % frames to get 3 values and check that they are inside precision of
    % each other
  end
  methods
    function a = DT9602R(comPort)
      % check nargin
      if nargin<1,
        error('DT9602R:constructor','Use a the com port, e.g. ''COM5'' as input argument to connect to the real board');
      end
      
      % check port
      if ~ischar(comPort),
        error('DT9602R:constructor','The input argument must be a string, e.g. ''COM8'' ');
      end
      
      % define serial object
      a.s = serial(comPort,'BaudRate',2400,'RequestToSend','off',...
        'InputBufferSize',AVP.HW.DT9602R.frame_size*...
        (AVP.HW.DT9602R.num_frames+1),'TimeOut',2);
      % +1 in case first frame is not complete
      
      fopen(a.s);
      disp('DT9602R successfully connected !');
    end
    
    % distructor, deletes the object
    function delete(a)
      % if it is a serial, valid and open then close it
      fclose(a.s);
    end % delete
    
    function [value, prec] = read(a,varargin)
      AVP.opt_param('precision',0.1);
      AVP.opt_param('timeout',10);
      pause(AVP.opt_param('delay',0));

      flushinput(a.s)
      
      value_buf = [];
      sample_buf = [];
      start = tic;
      while 1
        while a.s.BytesAvailable < AVP.HW.DT9602R.frame_size
          drawnow
        end
        frame = fread(a.s,AVP.HW.DT9602R.frame_size);
        if frame(end-1) ~= 13 || frame(end) ~= 10, % lost sync
          fread(a.s,mod(find(frame == 13) + 1,AVP.HW.DT9602R.frame_size));
        end
        % frame looks good , lets calculate value
        sample_buf = [sample_buf, AVP.HW.DT9602R.convert_frame(frame)];
        if numel(sample_buf) >= 3
          value_buf = [value_buf, AVP.HW.DT9602R.extrapolate(sample_buf(end-2:end))];
          if numel(value_buf) >= 3
            prec = max(abs([value_buf(end)-value_buf(end-1),value_buf(end-1)-value_buf(end-2)]));
            if prec <= precision
              value = value_buf(end);
              break;
            end
          end
        end
        if toc(start) > timeout
          error('"read" timed out trying to reach precision')
        end
      end
    end % read
  end % methods
  
  methods(Static)
    function [value, mode1, mode2, unit] = convert_frame(frame)
      % sign
      if frame(1) == '-', sign = -1; else sign = 1; end
    
      % place of digital point, only one bit is on
      switch(bitand(frame(7),7))
        case 4, dp = 0.1;
        case 2, dp = 0.01;
        case 1, dp = 0.001;
        otherwise, dp = NaN;
      end
      % prefix
      switch(bitand(frame(10),240))
        case 128, power = 1e-6;
        case 64, power = 1e-3;
        case 32, power = 1e3;
        case 16, power = 1e6;
        case 0, power = 1;
        otherwise, power = NaN;
      end
      
      mode1 = frame(8); 
    %  0x80	  0x40	0x20	       0x10	0x8	  0x4	        0x2	  0x1
    % Unknown	Delta	Auto-ranging	DC	AC	'Delta mode'	Hold	Ground-reference?
      mode2 = frame(9);
    % 0x80	  0x40	 0x20	0x10	0x8	         0x4	    0x2	     0x1
    % Unknown	Unknown	Max	Min	'Low Battery'	Unknown	Capacitor	Unknown  
      unit = frame(11);
    % 0x80	0x40	0x20	0x10	 0x8	         0x4	                0x2	    0x1
    % Volts	Amps	Ohms	Unknown	Hz	'Farads (Prefix is wrong)'	Celsius	Fahrenheit
      value = sign*sum(bitand(frame(2:5),15).' .* 10.^[3:-1:0])*dp*power;
    end
    
    function [value, A, Q] = extrapolate(x)
      %> @param x is the sequence of 3 consequitive samples
      % extrapolating assuming we have an exponenta degrading to a single
      % value x = x0 + A*exp(-l*i) = x0 + A*Q^i, where i is sample index.
      % We can get the three parameters from the three samples. Lets the
      % last sample number have index 0, so we have indexes -2,-1,0
      % x(3) - x(2) = A*(1-Q), x(2)-x(1)=A*Q*(1-Q).
      if x(3) == x(2)
        Q = []; A = 0;
      else
        Q = (x(2)-x(1))/(x(3) - x(2));
        A = (x(3) - x(2))/(1-Q);
      end
      value = x(3)-A;
    end
  end
end


