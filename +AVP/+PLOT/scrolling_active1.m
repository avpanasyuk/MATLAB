classdef scrolling_active1 < AVP.PLOT.scrolling1
  %> SCROLLING_ACTIVE1 is given a callback function and it calls it by
  %> itself. It differs from SCROLLING_ACTIVE because it uses
  %> POINT structure everywhere instead of separate X and Y
  %> After object construction START starts scrolling and
  %> STOP ends it
  properties (SetAccess=protected,GetAccess=protected)
    func
    timer
  end
  
  
  methods
    function a=scrolling_active1(func,period,varargin)
      %> @param func - should return POINTS struct('x', Xvector, 'Y', Ymatrix)
      %> or cell array of such structs
      %> X may be either size(Y,1) vector or empty vector. Y is either
      %> [numpoints, numvars] matrix ot [numpoints] vector
      %> @param period in seconds
      
      % ok, we can set things up only after we know what func returns, and
      % it may start returning something only later. So, we postpone
      % setting things up until the last moment
      a@AVP.PLOT.scrolling1(varargin{:});
      a.timer = timer('ExecutionMode','fixedSpacing','timerFcn',@(varargin) a.timer_func,...
        'Period',period,'BusyMode','drop');

      a.func = func;
      set(gcf,'DeleteFcn',@(varargin) a.delete);
      a.start
    end % scrolling_active
    
    function delete(a)
      a.stop
      delete(a.timer)
    end
    
    function timer_func(a)
      %try
        a.AddPoints(a.func())
       %catch ME1
        %if ~strcmp(ME1.identifier,'lock_commands:Locked'), rethrow(ME1); end
      %end
    end % first_time_func
    
    function start(a), start(a.timer); end
    function stop(a), stop(a.timer); end
  end % methods
end % scrolling_active
