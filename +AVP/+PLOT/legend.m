% automatically labels lines of current plot with numbers
function [ax,objs,ploth,texth] = legend(varargin)
  n = numel(get(gca,'Children'));
  [ax,objs,ploth,texth] = legend(cellstr(num2str([1:n].')),varargin{:});
  [objs(n+1:2:end).LineWidth] = deal(4);
end