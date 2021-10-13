classdef scrolling1 < handle
  %> this is a passive class, it is not trying to get data by itself, you can
  %> add point by calling "AddPoints"
  %> it differs from SCROLLING because it uses
  %> POINT structure everywhere instead of separate X and Y
  
  properties (SetAccess=protected,GetAccess=public)
    AxesArray = {} % cell array of AVP.PLOT.scrolling_axes
  end
  
  properties (SetAccess=protected,GetAccess=protected)
    fig
    options = struct()
    current_subplotI = 1
  end
  
  methods
    function a=scrolling1(varargin)
      %> @param
      %> @param varargin
      %>    - do_abs, bool, if Y is complex whether plot ABS value or real
      %>      and imaginary as separate plots
      %>    - same_plot, bool, if Y has more then one
      %>      column, plot them all on the same subplot, or
      %>      plot each of them on a separate subplots
      %>    - show_std: show STD of Y in the plotted range either on Y axis
      %>      or in lehend if there are multiple plots
      %>    - Npoints defines number of points for all
      %>      subplots, they can be changed individually per
      %>      subplot later by changing a.AxesArray(?).Npoints
      %>    - same_x: x axis is the same for all plots
      
      a.fig = figure('DeleteFcn',@(varargin) a.delete,'BusyAction','cancel',...
        'Interruptible','off');
      a.options.Npoints = AVP.opt_param('Npoints',300);
      a.options.show_std = AVP.opt_param('show_std',false);
      a.options.do_abs = AVP.opt_param('do_abs',false);
      a.options.same_plot = AVP.opt_param('same_plot',false);
    end
    
    function delete(a)
      if ishandle(a.fig)
        close(a.fig)
      end
    end
    
    function AddPoints(a,P)
      %> adds points to all subplots simultaniously,
      %> creating them if necessary
      %> @param P - struct('X', X, 'Y', Y)
      %>   or cell array of such structs
      %>   - X may be either is either
      %>     [numpoints, numvars] matrix or [numpoints] vector or empty.
      %>   - Y is either
      %>     [numpoints, numvars] matrix or [numpoints] vector
      if isempty(P), return; end
      if iscell(P)
        a.options.same_plot = true; % each cell array element occupies only one subplot/SCROLLING_AXES
        for sI = 1:numel(P)
          a.current_subplotI = sI;
          subplot(numel(P),1,a.current_subplotI)
          a.AddPoints(P{sI})
        end
      else % P is not cell array
        if ~isreal(P.Y)
          if isfield(a.options,'do_abs') && a.options.do_abs
            P.Y = abs(P.Y);
          else
            P.Y = [real(P.Y),imag(P.Y)];
          end
        end
        
        if a.options.same_plot || size(P.Y,2) == 1
          %% Recursion ends HERE
          if numel(a.AxesArray) < a.current_subplotI
            a.AxesArray{a.current_subplotI} = ...
              AVP.PLOT.scrolling_axes('Npoints',a.options.Npoints,'show_std',a.options.show_std);
          else
            a.AxesArray{a.current_subplotI}.DoPlot(P);
          end
        else
          for sI = 1:size(P.Y,2)
            a.current_subplotI = sI;
            subplot(size(P.Y,2),1,a.current_subplotI)
            if ~isfield(P,'X') || isempty(P.X)
              a.AddPoints(struct('Y',P.Y(:,a.current_subplotI)));
            else
              switch size(P.X,2)
                case size(P.Y,2)
                  a.AddPoints(struct('X',P.X(:,a.current_subplotI),...
                    'Y',P.Y(:,a.current_subplotI)));
                case 1
                  a.AddPoints(struct('X',P.X,'Y',P(:,a.current_subplotI)));
                otherwise
                  error('Wrong second dimension of X!');
              end % switch
            end
          end
        end
      end % if iscell(P)      
    end % AddPoints
    
%     function do_same_x(a)
%       if isempty(a.AxesArray), return; end
%       minX = a.AxesArray{1}.Axes.XLim(1);
%       maxX = a.AxesArray{1}.Axes.XLim(2);
%       for sI = 2:numel(a.AxesArray)
%         if
%       end
%     end
  end % methods
end % classdef scrolling


