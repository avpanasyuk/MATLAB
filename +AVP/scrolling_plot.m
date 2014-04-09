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
      if ishandle(a.fig)
        delete(a.fig)
      end
    end
    
    function plot(a)
      old_gcf = gcf;
      set(0,'Currentfig',a.fig);
      if a.same_plot || size(a.data_y,2) == 1
        if isreal(a.data_y),
          plot(a.data_x,a.data_y,'XDataSource','a.data_x',...
            'YDataSource','a.data_y',a.plot_props{:});
        else
          plot(a.data_x,real(a.data_y),a.data_x,imag(a.data_y),'.-',...
            'XDataSource','a.data_x','YDataSource','a.data_y',a.plot_props{:});
        end
      else
        for vi=1:size(a.data_y,2)
          subplot(size(a.data_y,2),1,vi)
          if isreal(a.data_y),
            plot(a.data_x,a.data_y(:,vi),'XDataSource','a.data_x',...
              'YDataSource','a.data_y',a.plot_props{:,vi});
          else
            plot(a.data_x,real(a.data_y(:,vi)),a.data_x,imag(a.data_y(:,vi)),'.-',...
              'XDataSource','a.data_x','YDataSource',...
              ['a.data_y(:,' num2str(vi) ')'],a.plot_props{:,vi});
          end
          if ~isempty(a.plot_names),
            set(gca,'ylabel',a.plot_names{vi});
          end
        end
      end
      set(0,'Currentfig',old_gcf);
    end % first_plot
    
    function AddPoints(a,y,x)
      if nargin < 3,
        x = [1:size(y,1)].' + a.last_x;
        a.last_x = x(end);
      end
      
      a.data_y = [a.data_y;y];
      a.data_x = [a.data_x;x];
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


