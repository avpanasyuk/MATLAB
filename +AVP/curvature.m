function c = curvature(y,x)
  % nice precise calculation symmetrical with x and y.
  % correct everywhere.
  y = y(:); x = x(:);
  c = 2*(x(1:end-2).*(y(2:end-1)-y(3:end)) + ...
    x(2:end-1).*(y(3:end)-y(1:end-2)) + ...
    x(3:end).*(y(1:end-2)-y(2:end-1)))./...
    sqrt(((x(2:end-1)-x(3:end)).^2 + (y(2:end-1)-y(3:end)).^2).*...
    ((x(1:end-2)-x(3:end)).^2 + (y(1:end-2)-y(3:end)).^2).*...
    ((x(2:end-1)-x(1:end-2)).^2 + (y(2:end-1)-y(1:end-2)).^2));
  c = smooth([c(1);c;c(end)],3);
end



