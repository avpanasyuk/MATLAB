%> @brief this is a passive class, it is not trying to get data by itself, you can
%> add point by calling "AddPoints"
classdef scrolling_plot < handle
  properties (SetAccess=protected,GetAccess=public)
    % user parameters
    plot_names = {}
    x_npoints = 1000
    plot_props = {}
    same_plot = false
    period = 0.1 % seconds
    % service
    fig
    % subplots = []
    plots = {}
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
      end
      a.next_plot = cputime;
    end
    
    function delete(a)
      if ishghandle(a.fig)
        delete(a.fig)
      end
    end
    
    function AddPoints(a,y,x)
      if nargin < 3,
        x = [1:size(y,1)].' + a.last_x;
        a.last_x = x(end);
      end
      
      a.data_y = [a.data_y;y];
      if isempty(a.data_y), return; end
      
      a.data_x = [a.data_x;x(:)];
      if size(a.data_y,1) > a.x_npoints,
        a.data_y = a.data_y(end-a.x_npoints+1:end,:);
        a.data_x = a.data_x(end-a.x_npoints+1:end,:);
      end
      
      % refreshdata(a.fig,'caller');
      if cputime > a.next_plot
        if isempty(a.plots)
          %%% create plot structure
          %%%% save old figure
          old_gcf = gcf;
          set(0,'CurrentFigure',a.fig);
          
          Nplots = size(a.data_y,2);
          if Nplots == 1 || a.same_plot
            a.plots{1} = plot(a.data_x,a.data_y,a.plot_props{:});
            % a.subplots = gca;
            if ~isempty(a.plot_names), ylabel(a.plot_names{1}); end
          else
            for vi=1:Nplots
              subplot(Nplots,1,vi);
              a.plots{vi} = plot(a.data_x,a.data_y(:,vi),a.plot_props{:,vi});
              if ~isempty(a.plot_names)
                ylabel(a.plot_names{vi});
              end
            end
            set(0,'CurrentFigure',old_gcf)
          end
        else
          if a.same_plot
            set(a.plots{1},'XData',a.data_x,'YData',a.data_y);
          else
            for vi=1:numel(a.plots)
              set(a.plots{vi},'XData',a.data_x,'YData',a.data_y(:,vi));
            end
          end
        end
        a.next_plot = cputime + a.period;
        drawnow
      end
    end
    
    function reset(a)
      a.data_y = [];
      a.data_x = [];
    end
  end %methods
end % classdef scrolling_plot


