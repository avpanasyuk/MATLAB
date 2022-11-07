function [ht ha] = super_title(Text,varargin)
  AVP.opt_param('Interpreter','none');
  AVP.opt_param('HorizontalAlignment','center');
  AVP.opt_param('VerticalAlignment', 'top');
  AVP.opt_param('Position',[0.5 1]);
  
  ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off',...
    'Visible','off','Units','normalized', 'clipping' , 'off');
  ht = text(Position(1), Position(2), Text, varargin{:});
end

