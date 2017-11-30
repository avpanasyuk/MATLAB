% automatically labels lines of current plot with numbers
function legend(varargin)
  n = 1:numel(get(gca,'Children'));
  legend(cellstr(num2str(n(:))),varargin{:});
end