% automatically labels lines of current plot with numbers
function [ax,objs,ploth,texth] = legend(Labels,varargin)
  n = numel(get(gca,'Children'));
  if ~AVP.is_defined('Labels')
    Labels = cellstr(num2str([1:n].'));
  end
  [ax,objs,ploth,texth] = legend(Labels,varargin{:});
  [objs(n+1:2:end).LineWidth] = deal(4);
end
