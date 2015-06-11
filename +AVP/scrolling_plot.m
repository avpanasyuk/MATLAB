%> @brief this is a passive class, it is not trying to get data by itself, you can
%> add point by calling "AddPoints"
classdef scrolling_plot < handle
  properties (SetAccess=protected,GetAccess=public)
    % user parameters
    do_abs = false
    plot_names = {}
    x_npoints = 1000
    plot_props = {}
    same_plot = false
    period = 0.1 % seconds
    % service
    fig
    subplots = []
    data_y = []
    data_x = []
    last_x = 0
    next_plot % cputime of the last plot to avod calling too often
  end
  methods
    function a=scrolling_plot(options)
      a.fig = figure('DeleteFcn',@(varargin) a.delete,'BusyAction','cancel',...
        'Interruptible','off');
      if exist('options','var')
        if isfield(options,'plot_names'), a.plot_names = options.plot_names; end
        if isfield(options,'x_npoints'), a.x_npoints = options.x_npoints; end
        if isfield(options,'same_plot'), a.same_plot = options.same_plot; end
        if isfield(options,'plot_props'), a.plot_props = options.plot_props; end
        if isfield(options,'period'), a.period = options.period; end
        if isfield(options,'do_abs'), a.do_abs = options.do_abs; end
      end
      a.next_plot = cputime;
    end
    
    function delete(a)
      if ishandle(a.fig)
        delete(a.fig)
      end
    end
    
    function plot(a)
      if isempty(a.data_y), return; end
      if isempty(a.subplots),
        % create plot structure
        old_gcf = gcf;
        set(0,'CurrentFigure',a.fig);
        for vi=1:size(a.data_y,2)
          if a.same_plot, a.subplots(vi) = gca;
          else a.subplots(vi) = subplot(size(a.data_y,2),1,vi);
          end
        end
        set(0,'CurrentFigure',old_gcf);
      end
      
      for vi=1:size(a.data_y,2)
        if isreal(a.data_y),
          plot(a.subplots(vi),a.data_x,a.data_y(:,vi),a.plot_props{:,vi});
        else
          plot(a.subplots(vi),a.data_x,real(a.data_y(:,vi)),...
            a.data_x,imag(a.data_y(:,vi)),'.-',a.plot_props{:,vi});
        end
        if ~isempty(a.plot_names),
          set(a.subplots(vi),'ylabel',a.plot_names{vi});
        end
      end
    end % plot
    
    function AddPoints(a,y,x)
      if nargin < 3,
        x = [1:size(y,1)].' + a.last_x;
        a.last_x = x(end);
      end
      
      if a.do_abs a.data_y = [a.data_y;abs(y)]; 
      else a.data_y = [a.data_y;y]; end
      
      a.data_x = [a.data_x;x(:)];
      if size(a.data_y,1) > a.x_npoints,
        a.data_y = a.data_y(end-a.x_npoints+1:end,:);
        a.data_x = a.data_x(end-a.x_npoints+1:end,:);
      end
      % refreshdata(a.fig,'caller');
      if cputime > a.next_plot
        a.plot
        % drawnow
        a.next_plot = cputime + a.period;
      end
    end
    
    function reset(a)
      a.data_y = [];
      a.data_x = [];
    end
  end %methods
end % classdef scrolling_plot


