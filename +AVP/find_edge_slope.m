function [a,b] = find_edge_slope(y,x,edge)
  %> calculating edge slope by doing linear interpolation of some number of
  %> points from the edge and finding minimal std error vs this number
  %> @param edge 1 for left, 2 for right, both if not specified/empty
  
  y = y(:);
  n = numel(y);
  ns = [1:n].';
  if isempty(x), x = ns; else x = x(:); end
  
  x_s = cumsum(x);
  y_s = cumsum(y);
  x2_s = cumsum(x.^2);
  yx_s = cumsum(y.*x);
  
  t = x2_s - x_s.^2./ns;
   
  a = ((yx_s - x_s.*y_s./ns)./t).';
  b = ((y_s.*x2_s - x_s.*yx_s)./ns./t).';
  
  a_arr = repmat(a,n,1);
  b_arr = repmat(b,n,1);
  x_arr = repmat(x,1,n);
  y_arr = repmat(y,1,n);
  
  err = cumsum((y_arr - a_arr.*x_arr - b_arr).^2)./repmat(ns,1,n);  
end