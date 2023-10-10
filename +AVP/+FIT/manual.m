function [params, limits] = manual(func,data,init_params,limits,varargin)
  %> @param func - y = function(params,x)
  x = AVP.opt_param('x',1:numel(data));
  n = numel(init_params);
  params = init_params;
  if ~exist('limits','var') || isempty(limits), limits = cell(n,1); end
  ui = uifigure();
  grid = uigridlayout(ui);
  grid.RowHeight = {'1x'};
  scrolls = uigridlayout(grid);
  scrolls.ColumnWidth = {'1x','1x','10x','1x'}; % min, slider, max
  scrolls.RowHeight = repmat({'1x'},n,1);
  ax = axes(grid);
  Slides = {}; MinEntry = {}; MaxEntry = {}; ValEntry = {};

  function ChangeLimit(pI,MinOrMax,Value)
    limits{pI}(MinOrMax) = Value;
    Slides{pI}.Limits = limits{pI};
    if MinOrMax == 1 && Value > params(pI)
      ChangeValue(pI, Value);
    end
  end % ChangeLimit

  function ChangeValue(pI, Value)
    params(pI) = min([max([Value limits{pI}(1)]) limits{pI}(2)]);
    plot(ax,x,data,'+');
    line(ax,x,func(params,x));
    title(ax,func2str(func));
    ValEntry{pI}.Value = params(pI);
    Slides{pI}.Value = params(pI);
  end % ChangeLimit

  for pI = 1:n
    if isempty(limits{pI})
      if init_params(pI) > 0
        limits{pI} = init_params(pI)*2.^[-1,1] + [-1,1];
      else
        limits{pI} = init_params(pI)*2.^[1,-1] + [-1,1];
      end        
    end
    uilabel(scrolls,"Text",['p' num2str(pI)]);
    MinEntry{pI} = uieditfield(scrolls,"numeric");
    MinEntry{pI}.Value = limits{pI}(1);
    MinEntry{pI}.Limits = [-Inf, limits{pI}(2)];
    MinEntry{pI}.ValueChangedFcn = @(obj,data) ChangeLimit(pI,1,data.Value);

    el = uipanel(scrolls);
    ValEntry{pI} = uieditfield(el,"numeric");
    ValEntry{pI}.ValueChangedFcn = @(obj,data) ChangeValue(pI, data.Value);
    Slides{pI} = uislider(el);
    Slides{pI}.Limits = limits{pI};
    Slides{pI}.ValueChangedFcn = @(obj,data) ChangeValue(pI, data.Value);

    MaxEntry{pI} = uieditfield(scrolls,"numeric");
    MaxEntry{pI}.Value = limits{pI}(2);
    MaxEntry{pI}.Limits = [limits{pI}(1), Inf];
    MaxEntry{pI}.ValueChangedFcn = @(obj,data) ChangeLimit(pI,2,data.Value);

    ChangeValue(pI,params(pI));
  end
  uiwait(ui)
end
