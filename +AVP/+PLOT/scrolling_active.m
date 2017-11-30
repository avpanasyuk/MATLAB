%> @brief scrolling_plot_active is given a callback function and it calls it by
%> itself
%> @param func 
classdef scrolling_plot_active < AVP.PLOT.scrolling
  properties (SetAccess=protected,GetAccess=public)
    %defiined properties
    y_only
    % service properties
    timer_obj
    func
  end
  methods
    %> @param func -should provide either Y or [Y,X] vectors. Y is of [samples,
    %> variables]  dimention
    %> [Ys(numvars,numpoints)] = func() or
    %> [Ys(numvars,numpoints),Xs(numpoints)] = func() or
    %> [Y_name{numvars}] = func(1)
    %> @param period in seconds
    function a=scrolling_plot_active(func,period,varargin)
      % ok, we can set things up only after we know what func returns, and
      % it may start returning something only later. So, we postpone
      % setting things up until the last moment
      a = a@AVP.PLOT.scrolling(varargin{:});
      % set(a.fig,'DeleteFcn',@(varargin) a.delete); - no need, where is
      % no virtual functions in MATLAB
      a.y_only = AVP.opt_param('y_only',[]);
      a.func = func;      
      a.timer_obj = timer('ExecutionMode','fixedSpacing',...
        'Period',period,'timerFcn',@(varargin) a.timer_func,...
        'BusyMode','drop');
      set(a.fig,'DeleteFcn',@(varargin) a.delete);
      a.start
    end % scrolling_plot_active
    
    function delete(a)
      if isvalid(a.timer_obj)
        a.stop
        delete(a.timer_obj)
      end
      delete@AVP.PLOT.scrolling(a)
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
        if a.y_only
          Y = a.func();
          a.AddPoints(Y)
        else
          [Y,X] = a.func();
          a.AddPoints(Y,X)
        end
      catch ME1
        if ~strcmp(ME1.identifier,'lock_commands:Locked'), rethrow(ME1); end
      end
    end % first_time_func
    
    function start(a), start(a.timer_obj); end
    function stop(a), stop(a.timer_obj); end
  end % methods
end % scrolling_plot_active
