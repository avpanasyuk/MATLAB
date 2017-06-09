%> @brief this is a passive class, it is not trying to get data by itself, you can
%> add point by calling "AddPoints"
classdef scrolling_plot < handle
  properties (SetAccess=protected,GetAccess=public)
    % user parameters
    plot_names
    x_npoints
    plot_props
    same_plot
    do_abs
    show_std
    % service
    fig = []
    plots = {}
    data_y = [] % used only when not same_plot, because we slit data between subplots in this case
    data_x = []
    start_x = 0
    legend
    ylabels
    x_start_lbl
    next_plot % cputime of the last plot to avod calling too often
  end
  methods
    function a=scrolling_plot(varargin)
      a.fig = figure('DeleteFcn',@(varargin) a.delete,'BusyAction','cancel',...
        'Interruptible','off');
      a.plot_names = AVP.opt_param('plot_names',{});
      a.x_npoints = AVP.opt_param('x_npoints',1000);
      a.same_plot = AVP.opt_param('same_plot',false);
      a.plot_props = AVP.opt_param('plot_props',{});
      a.do_abs = AVP.opt_param('do_abs',false);
      a.show_std = AVP.opt_param('show_std',false);
      a.next_plot = cputime;
      
      if ~isempty(a.plot_names) && a.show_std
        warning('"show_std" suppresses "plot_names"')
      end
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
          if a.show_std
            a.legend = legend(cell(1,size(a.data_y,2)));
          else
            if ~isempty(a.plot_names), legend(a.plot_names); end
          end
          axis tight
        else
          for pli=1:n_vars
            subplot(n_vars,1,pli)
            a.plots{pli} = plot(a.data_x(:,pli),a.data_y(:,pli),a.plot_props{:});
            if a.show_std
              a.ylabels{pli} = ylabel('');
            else
              if ~isempty(a.plot_names)
                if numel(a.plot_names) ~= n_vars
                  error('Wrong number of label strings!');
                end
                ylabel(a.plot_names{pli});
              end
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
          if a.show_std
            a.legend.String = AVP.num2str(AVP.rel_std(a.data_y),'%6.2e');
          end
        else
          for pli=1:n_vars
            a.plots{pli}.XData = a.data_x(:,pli);
            a.plots{pli}.YData = a.data_y(:,pli);
            % keyboard
            if a.show_std
              a.ylabels{pli}.String = num2str(AVP.rel_std(a.data_y(:,pli)),'%6.2e');
            end
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


