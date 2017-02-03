%> @brief this is a passive class, it is not trying to get data by itself, you can
%> add point by calling "AddPoints"
classdef scrolling_plot < handle
  properties (SetAccess=protected,GetAccess=public)
    % user parameters
    plot_names = {}
    x_npoints = 1000
    plot_props = {}
    same_plot = false
    do_abs = false
    % service
    fig = []
    plots = {}
    data_y = [] % used only when not same_plot, because we slit data between subplots in this case
    data_x = []
    start_x = 0
    x_start_lbl
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
        if isfield(options,'min_period'), a.min_period = options.min_period; end
        if isfield(options,'do_abs'), a.do_abs = options.do_abs; end
      end
      a.next_plot = cputime;
    end
    
    function delete(a)
      if ishandle(a.fig)
        close(a.fig)
      end
    end
    
    function AddPoints(a,y,x)
      %> @param y - array[SampleI, ParamI]
      %> @param x - vector[SampleI]
      if isempty(y), return; end
      if ~isreal(y) && ~a.do_abs, y = [real(y),imag(y)]; end
        
      n_vars = size(y,2);
      
      % merge data with old track
      % X 
      if ~exist('x','var')
        x = [1:size(y,1)].';
        if ~isempty(a.data_x), x = x + a.data_x(end,1); end
      else
        x = x - a.start_x;
      end
      if size(x,2) ~= n_vars
        if size(x,2) ~= 1, error('Wrong X size'); end
        x = repmat(x,1,n_vars);
      end
      
      a.data_x = [a.data_x;x];
      % Y
      if a.do_abs, y = abs(y); end
      a.data_y = [a.data_y;y];
      
      % trim data
      if size(a.data_y,1) > a.x_npoints,
        a.data_y = a.data_y(end-a.x_npoints+1:end,:);
        a.data_x = a.data_x(end-a.x_npoints+1:end,:);
      end
      
      a.start_x = a.start_x + min(a.data_x(1,:));
      x_lbl_str = sprintf('+%f',a.start_x);
      a.data_x = a.data_x - min(a.data_x(1,:));
      
      % plot data
      
      if isempty(a.plots) % called for the first time
        old_gcf = gcf;
        set(0,'CurrentFigure',a.fig);
        % create all plots
        if a.same_plot
          a.plots = plot(a.data_x,a.data_y,a.plot_props{:});
          if ~isempty(a.plot_names), legend(a.plot_names); end
          axis tight
        else
          for pli=1:n_vars
            subplot(n_vars,1,pli)
            a.plots{pli} = plot(a.data_x(:,pli),a.data_y(:,pli),a.plot_props{:});
            if ~isempty(a.plot_names)
              if numel(a.plot_names) ~= n_vars
                error('Wrong number of label strings!');
              end
              ylabel(a.plot_names{pli}); 
            end
            axis tight
            if pli == n_vars, a.x_start_lbl = xlabel(x_lbl_str); end
          end
        end
        set(0,'CurrentFigure',old_gcf);
        set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
      else
        if a.same_plot
          a.plots.XData = a.data_x;
          a.plots.YData = a.data_y;
        else
          for pli=1:n_vars
            a.plots{pli}.XData = a.data_x(:,pli);
            a.plots{pli}.YData = a.data_y(:,pli);
          end
        end
        a.x_start_lbl.String = x_lbl_str;
      end
      drawnow
    end % AddPoints
    
    function reset(a)
      a.data_y = [];
       a.data_x = [];
    end
    
    function [y x] = get_median(a)
      y = median(a.data_y);
      x = mediam(a.data_x);
    end
  end %methods
end % classdef scrolling_plot


