classdef scrolling_axes < handle
  %> this class corresponds to a single subplot in SCROLLING1 panel
  %> it may handle a single plot is Y is vector or multiple
  %> if it is a matrix
  properties
    Axes
    Npoints = 300 %> maximum number of points in the subplot can be set to
    %> a different value in run-time
    XLabel = ''
    YLabel = ''
    legend
  end
  
  properties (SetAccess=protected,GetAccess=protected)
    Xlabel
    StartX = 0 %>> beginning of the X axes
    show_std
  end
  
  methods
    function a = scrolling_axes(varargin)
      %> @param varargin
      %>   - Npoints: number of points from the end to
      %>     plot, default 300.
      %>   - show_std: show STD of Y in the plotted range either on Y axis
      %>     or in lehend if there are multiple plots
      %>
      a.Axes = gca;
      a.Npoints = AVP.opt_param('Npoints',300);
      a.show_std = AVP.opt_param('show_std',false);
    end % constructor
    
    function DoPlot(a,P,varargin)
      %> @param P - struct('X', Xvector, 'Y', Ymatrix)
      %>   - X may be either is either
      %>     [numpoints, numvars] matrix or [numpoints] vector or empty vector.
      %>   - Y is either
      %>     [numpoints, numvars] matrix or [numpoints] vector
      subplot(a.Axes)
      if isempty(a.Axes.Children) % no Lines - nothing is plotted yet
        %% this branch executes only once on the first call
        if isfield(P,'X') && ~isempty(P.X)
          plot(P.X,P.Y,varargin{:})
        else
          plot(P.Y,varargin{:})
        end
        if numel(P.Y,2) ~= 1
          a.legend = legend;
          a.YLabel = cell(numel(P.Y,2),1);
          [a.YLabel{:}] = deal('');
        end
      else % we already have plots
        if numel(P.Y,2) ~= numel(a.Axes.Children)
          error('Wrong number or variables (the second dimension) in Y!')
        end
        
        for LineI = 1:numel(P.Y,2)
          if ~isfield(P,'X') || isempty(P.X)
            x = [1:size(P.Y,1)].' + a.Axes.Children(LineI).XData(end) + a.StartX;
          else
            x = P.X(:);
          end
          
          NewY = [a.Axes.Children(LineI).YData, P.Y(:,LineI).'];
          if size(x,2) == 1
            NewX = [a.Axes.Children(LineI).XData + a.StartX, x(:).'];
          else
            NewX = [a.Axes.Children(LineI).XData + a.StartX, x(:,LineI).'];
          end
          
          if numel(NewY) > a.Npoints
            NewY = NewY(end - a.Npoints + 1:end);
            NewX = NewX(end - a.Npoints + 1:end);
          end
          
          std_str{LineI} = AVP.CONVERT.num2str(AVP.rel_std(NewY),'%6.2e');
          set(a.Axes.Children(LineI),'XData',NewX,'YData',NewY);
        end
        %% I want to keep X label to a short number so they fit on the axis,
        % so I offset them by StartX
        a.StartX = a.Axes.XLim(1);
        for LineI = 1:numel(P.Y,2)
          set(a.Axes.Children(LineI),'XData',NewX -  a.StartX,'YData',NewY);
        end
        if a.show_std
          if numel(P.Y,2) == 1
            ylabel([a.YLabel, 'std(Y) = ', std_str{1}])
          else
            a.legend.String = strcat(a.YLabel,std_str);
          end
        end
      end
      xlabel([a.XLabel, ', StartX = ', num2str(a.StartX)])
      drawnow
    end% DoPlot
    
    
    %
    %
    %
    %       if size(x,2) ~= n_vars
    %         if size(x,2) ~= 1, error('Wrong X size'); end
    %         x = repmat(x,1,n_vars);
    %       end
    %
    %       a.data_x = [a.data_x;x];
    %       % Y
    %       if a.do_abs, y = abs(y); end
    %       a.data_y = [a.data_y;y];
    %
    %       % trim data
    %       if size(a.data_y,1) > a.x_npoints,
    %         a.data_y = a.data_y(end-a.x_npoints+1:end,:);
    %         a.data_x = a.data_x(end-a.x_npoints+1:end,:);
    %       end
    %
    %       a.start_x = a.start_x + min(a.data_x(1,:));
    %       x_lbl_str = sprintf('+%f',a.start_x);
    %       a.data_x = a.data_x - min(a.data_x(1,:));
    %
    %       % plot data
    %
    %       if isempty(a.plots) % called for the first time
    %         old_gcf = gcf;
    %         set(0,'CurrentFigure',a.fig);
    %         % create all plots
    %         if a.same_plot
    %           a.plots = plot(a.data_x,a.data_y,a.plot_props{:});
    %           if a.show_std
    %             a.legend = legend(cell(1,size(a.data_y,2)));
    %           else
    %             if ~isempty(a.plot_names), legend(a.plot_names); end
    %           end
    %           axis tight
    %         else
    %           for pli=1:n_vars
    %             subplot(n_vars,1,pli)
    %             a.plots{pli} = plot(a.data_x(:,pli),a.data_y(:,pli),a.plot_props{:});
    %             if a.show_std
    %               a.ylabels{pli} = ylabel('');
    %             else
    %               if ~isempty(a.plot_names)
    %                 if numel(a.plot_names) ~= n_vars
    %                   error('Wrong number of label strings!');
    %                 end
    %                 ylabel(a.plot_names{pli});
    %               end
    %             end
    %             axis tight
    %             if pli == n_vars, a.x_start_lbl = xlabel(x_lbl_str); end
    %           end
    %         end
    %         set(0,'CurrentFigure',old_gcf);
    %         set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
    %       else
    %         if a.same_plot
    %           a.plots.XData = a.data_x;
    %           a.plots.YData = a.data_y;
    %           if a.show_std
    %             a.legend.String = AVP.CONVERT.num2str(AVP.rel_std(a.data_y),'%6.2e');
    %           end
    %         else
    %           for pli=1:n_vars
    %             a.plots{pli}.XData = a.data_x(:,pli);
    %             a.plots{pli}.YData = a.data_y(:,pli);
    %             % keyboard
    %             if a.show_std
    %               a.ylabels{pli}.String = num2str(AVP.rel_std(a.data_y(:,pli)),'%6.2e');
    %             end
    %           end
    %         end
    %         a.x_start_lbl.String = x_lbl_str;
    %       end
    %       drawnow
    %     end % DoPlot
  end % methods
end % scrolling_axes