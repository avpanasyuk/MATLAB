function [params, limits] = manual(func,data,init_params,limits,varargin)
  %> @param func - y = function(params,x)
  x = AVP.opt_param('x',1:numel(data));
  n = numel(init_params);
  par_names = AVP.opt_param('par_names',strcat('p',strsplit(num2str(1:n))));
  params = init_params;
  if ~exist('limits','var') || isempty(limits), limits = cell(n,1); end
  ui = uifigure();
  ui.Position(3:4) = [1000 1000];
  
  grid = uigridlayout(ui,[1 2]);
  % grid.RowHeight = {'1x'};
  % grid.ColumnWidth = {'1x','1x'};
  
  left_col = uigridlayout(grid,[n+1 1]); % top row are buttons, others - sliders
  % left_col.ColumnWidth = {'1x'}; 
  % left_col.RowHeight = repmat({'1x'},n+1,1);

  controls = uigridlayout(left_col, [1 1]);
  controls.RowHeight = {'fit'};

  do_fit = uibutton(controls);
  do_fit.Text = 'FITNLM';

  %%%%%%%%%%%%%%%%%% NESTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function ChangeLimit(pI,MinOrMax,Value)
    limits{pI}(MinOrMax) = Value;
    Slides{pI}.Limits = limits{pI};
    if MinOrMax == 1
      MinEntry{pI}.Value = Value;
      if Value > params(pI)
        ChangeValue(pI, Value);
      end
      MaxEntry{pI}.Value = Value;
      if Value < params(pI)
        ChangeValue(pI, Value);
      end
    end
  end % ChangeLimit

  function ChangeValue(pI, Value, Force)
    if AVP.is_true('Force')
      if Value < limits{pI}(1), ChangeLimit(pI,1,Value); end
      if Value > limits{pI}(2), ChangeLimit(pI,2,Value); end
      params(pI) = Value;
    else      
      params(pI) = min([max([Value limits{pI}(1)]) limits{pI}(2)]);
    end
    plot(ax,x,data,'+');
    line(ax,x,func(params,x));
    title(ax,func2str(func));
    ValEntry{pI}.Value = params(pI);
    Slides{pI}.Value = params(pI);     
  end % ChangeLimit

  function do_fitnlm(obj,event)
    f1 = fitnlm(x,data,func,params,varargin{:});
    for pI = 1:numel(params)
      ChangeValue(pI,f1.Coefficients.Estimate(pI),true);
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  do_fit.ButtonPushedFcn  = @do_fitnlm;

  ax = axes(grid);

  Slides = {}; MinEntry = {}; MaxEntry = {}; ValEntry = {};

  for pI = 1:n
    if isempty(limits{pI})
      if init_params(pI) > 0
        limits{pI} = init_params(pI)*2.^[-1,1] + [-1,1];
      else
        limits{pI} = init_params(pI)*2.^[1,-1] + [-1,1];
      end        
    end

    param_panel = uigridlayout(left_col,[1 2]);
    param_panel.ColumnWidth = {'fit','1x'};
    param_panel.RowHeight = {'1x'};
    t = uilabel(param_panel,"Text",par_names{pI});

    slider_panel = uigridlayout(param_panel,[2 1]);
    % slider_panel.ColumnWidth = {'1x'};
    % slider_panel.RowHeight = {'1x','1x'};
    
    edits = uigridlayout(slider_panel,[1 3]);
    % edits.ColumnWidth = {'1x','1x','1x'};


    MinEntry{pI} = uieditfield(edits,"numeric","HorizontalAlignment","left");
    MinEntry{pI}.Value = limits{pI}(1);
    MinEntry{pI}.ValueChangedFcn = @(obj,data) ChangeLimit(pI,1,data.Value);

    ValEntry{pI} = uieditfield(edits,"numeric","HorizontalAlignment","center");
    ValEntry{pI}.ValueChangedFcn = @(obj,data) ChangeValue(pI, data.Value);

    MaxEntry{pI} = uieditfield(edits,"numeric","HorizontalAlignment","right");
    MaxEntry{pI}.Value = limits{pI}(2);
    MaxEntry{pI}.ValueChangedFcn = @(obj,data) ChangeLimit(pI,2,data.Value);

    Slides{pI} = uislider(slider_panel);
    Slides{pI}.Limits = limits{pI};
    Slides{pI}.ValueChangedFcn = @(obj,data) ChangeValue(pI, data.Value);

    ChangeValue(pI,params(pI));
  end
  uiwait(ui)
end
