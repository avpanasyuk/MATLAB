function [ht ha] = super_title(Text,varargin)
  ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off',...
    'Visible','off','Units','normalized', 'clipping' , 'off');
  ht = text(0.5, 1,Text,'Interpreter','none','HorizontalAlignment',...
    'center','VerticalAlignment', 'top',varargin{:});
end

