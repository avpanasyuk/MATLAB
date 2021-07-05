% automatically labels lines of current plot with numbers
function [ax,objs,ploth,texth] = legend(varargin)
  n = numel(get(gca,'Children'));
  if numel(varargin{1}) == n, labels = varargin{1}; 
  else labels = cellstr(num2str([1:n].'));
  end
  [ax,objs,ploth,texth] = legend(labels,varargin{2:end});
  [objs(n+1:2:end).LineWidth] = deal(4);
end