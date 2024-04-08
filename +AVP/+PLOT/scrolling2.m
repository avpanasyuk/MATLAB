classdef scrolling2 < handle
  %> @brief this is a passive class, it is not trying to get data by itself, you can
  %> add point by calling "AddPoints"
  %> corresponds to a single figure, but possibly multiple subplots
  %> to set line properties do, e.g. a.fig.Children(plotI).Children(LineI).Color = 'red';
  properties (SetAccess=protected,GetAccess=public)
    % user parameters
    fig = {} %>< We can change everything using this handle, like
    %> a.fig.Children(subplotI).Children(LineI).Color = 'red';
    npoints
    same_plot % if y is not a cell array, do we plot all coulmn on a same plot or not
  end % properties

  methods(Static)
    function x = MakeX(y,prev_x_end)
      %> @param prev_x_end is either scalar of vector by variable index
      x = [1:size(y,1)].';
      if size(y,2) > 1, x = repmat(x,1,size(y,2)); end
      if numel(prev_x_end) ~= 1,  prev_x_end = repmat(prev_x_end,size(y,1),1); end
      x = x + prev_x_end;
    end % MakeX

    function AppendPointsToLines(line_handles,y,x,max_points)
      %> @param line_handles - vector of existing line handles
      %> @param y - matrix (SampleI, VarI)
      %> @param x - empty, or Vector(SampleI), or matrix (SampleI, VarI)
      for lI = numel(line_handles)
        if isempty(x)
          x_ = [1:size(y,1)] + line_handles(lI).XData(end);
        else
          if size(x,2) > 1, x_ = x(:,lI).'; else x_ = x(:).'; end
        end
        line_handles(lI).YData = [line_handles(lI).YData,y(:,lI).'];
        line_handles(lI).XData = [line_handles(lI).XData,x_];

        % check whether we have to trim the beginning of the plot
        NtoDelete = numel(line_handles(lI).YData) - max_points;
        if NtoDelete > 0
          line_handles.YData(1:NtoDelete) = [];
          line_handles.XData(1:NtoDelete) = [];
        end %  we have to trim
      end
    end % AppendPointsToLines
  end % static methods

  methods
    function a=scrolling2(varargin)
      a.fig = figure('BusyAction','cancel','Interruptible','off');
      a.npoints = AVP.opt_param('x_npoints',200);
      a.same_plot = AVP.opt_param('same_axes',false);
    end % constructor

    function delete(a)
      if ishandle(a.fig)
        close(a.fig)
      end
    end

    function AddPoints(a,y,x)
      %> @param y - either array[SampleI, VarI] or cell
      %> array {VarI} of y vectors[SampleI]
      %> @param x - either empty or vector[SampleI] or array[SampleI, VarI] or cell
      %> array {VarI} of x vectors. It should be a continuation of previous
      %> x
      if isempty(y), return; end
      if ~exist('x','var'), x = []; end % I want to be able to pass it to functions

      if iscell(y)
        if numel(y) ~= numel(a.fig.Children) % create new plots          
          old_gcf = gcf;
          set(0,'CurrentFigure',a.fig);
          clf
          for pI = 1:numel(y)
            subplot(numel(y),1,pI)
            if isempty(x), x = [1:size(y{pI},1)].'; end
            if iscell(x)
              plot(x{pI},y{pI});
            else
              plot(x,y{pI});
            end
            axis tight
          end
          set(0,'CurrentFigure',old_gcf);
          set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
        else % add to the old subplots
          for pI = 1:numel(y)
            if numel(a.fig.Children(pI)) ~= size(y,2) % % create new plot
              old_gcf = gcf;
              set(0,'CurrentFigure',a.fig);
              clf
              subplot(numel(y),1,pI)
              plot(x,y{pI});
              axis tight
              set(0,'CurrentFigure',old_gcf);
              set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
            else % add to the old subplots
              AVP.PLOT.scrolling2.AppendPointsToLines(a.fig.Children(pI).Children,y,x,a.npoints);
            end
          end
        end
      else % y is not a cell array
        if a.same_plot || size(y,2) == 1 % a single subplot
          if numel(a.fig.Children) == 1 && numel(a.fig.Children(1)) == size(y,2) % add to the old plots
            AVP.PLOT.scrolling2.AppendPointsToLines(a.fig.Children(1).Children,y,x,a.npoints);
          else % create new plots
            old_gcf = gcf;
            set(0,'CurrentFigure',a.fig);
            clf
            if isempty(x), x = AVP.PLOT.scrolling2.MakeX(y,0); end
            plot(x,y);
            axis tight
            set(0,'CurrentFigure',old_gcf);
            set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
          end
        else % many subplots
          if numel(a.fig.Children) == size(y,2) % add to the old plots
            for pI = 1:size(y,2)
              AVP.PLOT.scrolling2.AppendPointsToLines(a.fig.Children(pI).Children,y(:,pI),x,a.npoints);
            end
          else % create new plots
            old_gcf = gcf;
            set(0,'CurrentFigure',a.fig);
            clf
            if isempty(x), x = AVP.PLOT.scrolling2.MakeX(y,0); end
            for pI = 1:size(y,2)
              subplot(size(y,2),1,pI)
              if size(x,2) > 1
                plot(x(:,pI),y(:,pI));
              else
                plot(x,y(:,pI));
              end
              axis tight
            end
            set(0,'CurrentFigure',old_gcf);
            set(a.fig,'HandleVisibility','callback') % figure is not visible from CLI
          end
        end
      end
    end %AddPoints
  end %methods
end % classdef scrolling


