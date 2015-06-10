%> @brief scrolling_plot_active is given a callback function and it calls it by
%> itself
classdef scrolling_plot_active < AVP.scrolling_plot
  properties (SetAccess=protected,GetAccess=public)
    %defiined properties
    y_only = []
    % service properties
    timer_obj
    func
  end
  methods
    %> @param func -
    %> [Ys(numvars,numpoints)] = func() or
    %> [Ys(numvars,numpoints),Xs(numpoints)] = func() or
    %> [Y_name{numvars}] = func(1)
    %> @param period in seconds
    function a=scrolling_plot_active(func,period,options)
      % ok, we can set things up only after we know what func returns, and
      % it may start returning something only later. So, we postpone
      % setting things up until the last moment
       
      if ~exist('options','var'), options = {}; 
      else
          if isfield(options,'y_only'), y_only = options.y_only; end
      end
      
      a = a@AVP.scrolling_plot(options);
      set(a.fig,'HandleVisibility','callback')
      % set(a.fig,'DeleteFcn',@(varargin) a.delete); - no need, where is
      % no virtual functions in MATLAB
      a.func = func;
      
      a.timer_obj = timer('ExecutionMode','fixedRate',...
        'Period',period,'timerFcn',@(varargin) a.timer_func,...
        'BusyMode','drop');
      a.start
    end % scrolling_plot_active
    
    function delete(a)
      if isvalid(a.timer_obj)
        a.stop
        delete(a.timer_obj)
      end
    end   
    
    function timer_func(a)
      Y = [];
      try
        if isempty(a.y_only)
          % if the callback is called for the first time we determine whether we are
          % getting any Xs
          try
            while isempty(Y), [Y,X] = a.func(); end
            a.y_only = false;
          catch ME
            if strcmp(ME.identifier,'MATLAB:maxlhs'), % function does not return X
              a.y_only = true;
            else
              rethrow(ME);
            end
            while isempty(Y), Y = a.func(); end
          end
        end
        if a.y_only,
          while isempty(Y), Y = a.func(); end
          a.AddPoints(Y)
        else
          while isempty(Y), [Y,X] = a.func(); end
          a.AddPoints(Y,X)
        end
      catch ME1
        if ~strcmp(ME1.identifier,'protocol:command_locked'), rethrow(ME1); end
      end
    end % first_time_func
    
    function start(a), start(a.timer_obj); end
    function stop(a), stop(a.timer_obj); end
  end % methods
end % scrolling_plot_active
