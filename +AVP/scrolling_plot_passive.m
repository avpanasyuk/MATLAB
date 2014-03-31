%> after object is created requires explicit calling AddPoints member
%> function to update plot
classdef scrolling_plot_passive < handle
  properties
    figure
    axes
    plot_names = {}
    x_npoints
    data_y = []
    data_x = []
    plot_props = {}
    last_x = 0
  end
  methods
    function a=scrolling_plot_passive(options,varargin)
      a.figure = figure('DeleteFcn',@(varargin) a.delete(),'BusyAction','cancel',...
        'Interruptible','off');
      a.axes=axes();
      a.plot_props = varargin;
      % rows are samples
      a.x_npoints = 1000;
      % names are just port numbers
      if exist('options','var')
        if isfield(options,'plot_names'), a.plot_names = options.plot_names; end
        if isfield(options,'x_npoints'), a.x_npoints = options.x_npoints; end
      end
    end
    
    function delete(a)
      if ishandle(a.figure)
        close(a.figure)
      end
    end
    
    %> @param y row vector or matrix with each row correcponding to one variable
    %> @param x vector with the same size as y rows
    function AddPoints(a,y,x)
      if isempty(y), return; end
      if nargin < 3,
        x = [a.last_x+1:a.last_x + size(y,2)];
        a.last_x = a.last_x + size(y,2);
      end
      if isempty(a.data_y)
        figure(a.figure)
        a.data_y = y;
        a.data_x = x;
        for vi=1:size(y,1)
          subplot(size(y,1),1,vi)
          plot(a.data_x,a.data_y,'XDataSource','a.data_x',...
            'YDataSource',['a.data_y(' num2str(vi) ',:)'],a.plot_props{:});
          if ~isempty(a.plot_names),
            set(gca,'ylabel',a.plot_names{vi});
          end
        end
      else
        a.data_y = [a.data_y,y];
        a.data_x = [a.data_x,x];
        if size(a.data_y,2) > a.x_npoints,
          a.data_y = a.data_y(:,end-a.x_npoints+1:end);
          a.data_x = a.data_x(:,end-a.x_npoints+1:end);
        end
        refreshdata(a.figure,'caller');
      end
    end %AddPoints 
  end %methods
end% classdef scrolling_plot_passive
