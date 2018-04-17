% automatically labels lines of current plot with numbers
function legend(varargin)
  n = numel(get(gca,'Children'));
  [~,lineh] = legend(cellstr(num2str([1:n].')),varargin{:});
  [lineh(n+1:2:end).LineWidth] = deal(4);
end