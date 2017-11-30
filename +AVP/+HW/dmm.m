classdef dmm < handle
  properties
    aser % serial port object
    pull_timer % timer object pulling data
    tic
    cur_values % current data frame
    cur_toc % corresponing time
    cur_frame = uint32(0); % we are trying to keep no frame in the device log 
    % but we still have to skip one frame after request for read, as it
    % still could be old frame from log. UPDATED counts frames
  end
  methods
    function a = dmm(comPort,options)
      Period = 0.5; % DT9602R gives datat once in 0.6 seconds
      if exist('options','var'),
        if isfield(options,'Period'), Period = options.Period; end
      else options = []; end

      
      % check nargin
      if nargin<1,
        error('DMM:constructor','Use a the com port, e.g. ''COM5'' as input argument to connect to the real board');
      end

      % check port
      if ~ischar(comPort),
        error('DMM:constructor','The input argument must be a string, e.g. ''COM8'' ');
      end

      % define serial object
      a.aser=serial(comPort,'BaudRate',2400,'RequestToSend','off',...
        'InputBufferSize',14,'TimeOut',2);
      
      a.pull_timer = timer('ExecutionMode','fixedDelay','Period',Period,...
        'TimerFcn',@timer_func);
      % a.pull_timer = timer('TimerFcn',@timer_func);

      function timer_func(varargin)
        while a.aser.BytesAvailable == 14, 
            a.cur_values = fread(a.aser,14);
            if a.cur_values(13) ~= 13 || a.cur_values(14) ~= 10, % lost sync
              fread(a.aser,mod(find(a.cur_values == 13) + 1,14));
            end
            a.cur_frame = a.cur_frame + 1;
            a.cur_toc = toc(a.tic);
        end
      end
      
      try
        fopen(a.aser);
        disp('DMM successfully connected !');
      catch ME,
        fclose(a.aser);
        delete(a.aser);
        rethrow(ME)
      end
      a.tic = tic;
      start(a.pull_timer)
    end
    
    % distructor, deletes the object
    function delete(a)
      % if it is a serial, valid and open then close it
      if isobject(a.pull_timer), delete(a.pull_timer); end
      if port_status(a), fclose(a.aser); end

      % if it's an object delete it
      if isobject(a.aser), delete(a.aser); end
    end % delete

    %%%%%%%%%%%%%%%% Serial port is OK
    function out = port_status(a)
      out = isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open');
    end % function port_status
    
    function value = read(a,options)
      % #################### optional parameters
      precision = 1; % we will measure repeatedly until result converges to
      % a given precision
      skip_frames = 1; % we skip this number of data frames before returning a 
      % does not make sense to use with "precision"
      max_samples = 20; % maximum number of times we read when we try to 
      % get to "precision". Does not work without "precision"

      if exist('options','var'),
        if isfield(options,'precision'), precision = options.precision; end
        if isfield(options,'skip_frames'), skip_frames = options.skip_frames; end
        if isfield(options,'max_samples'), max_samples = options.max_samples; end        
      else options = []; end

      if precision ~= 1, % we did specify precision, so we have to monitor convergence
        value = a.read; prev_read = 0; num_sample = 1;
        while abs(prev_read - value) > precision*abs(value) && ...
          num_sample < max_samples,
          prev_read = value;
          value = a.read;
          num_sample = num_sample + 1;
          drawnow;
        end
        if num_sample >= max_samples,
          error('dmm.read:BadPrec',['Value has not converged to specified ',...
            'precision in maximum number of iterrations!']);
        end
      else                
        cur_frame = a.cur_frame;
        while a.cur_frame < cur_frame + skip_frames + 1, drawnow; end

        % place of digital point, only one bit is on
        switch(bitand(a.cur_values(7),7))
          case 4, dp = 0.1;
          case 2, dp = 0.01;
          case 1, dp = 0.001;
          otherwise, dp = NaN;
        end
        % prefix
        switch(bitand(a.cur_values(10),240))
          case 128, power = 1e-6;
          case 64, power = 1e-3;
          case 32, power = 1e3;
          case 16, power = 1e6;
          case 0, power = 1;
          otherwise, power = NaN;
        end

        % decode value from a.cur_values
        value = sum(bitand(a.cur_values(2:5),15).' .* 10.^[3:-1:0])*dp*power;
      end
    end % read
 end % methods
end

	
      