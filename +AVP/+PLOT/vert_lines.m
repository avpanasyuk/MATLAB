function vert_lines(x,varargin)
  for xi=1:numel(x)
    plot([x(xi),x(xi)],get(gca,'YLim'),varargin{:}); 
  end
end
  