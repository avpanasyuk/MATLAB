% automatically labels lines of current plot with numbers
function [ax,objs,ploth,texth] = legend(Labels,varargin)
  AVP.opt_param('LineWidth',4,1);
  AVP.opt_param('MarkerSize',20,1); 
  
  n = numel(get(gca,'Children'));
  if ~AVP.is_defined('Labels')
    Labels = cellstr(num2str([1:n].'));
  end
  [ax,objs,ploth,texth] = legend(Labels,varargin{:});
  for Id = n+1:2:3*n-1
    objs(Id).LineWidth = LineWidth;
    objs(Id+1).MarkerSize = MarkerSize;
  end
%   AVP.opt_param('title_string','',1); 
%   if ~isempty(title_string)
%      ax.Title.String = title_string;
%      ax.Title.Visible = 1;
%   end
end
