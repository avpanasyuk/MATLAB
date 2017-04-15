function [ys ym] = smooth_with_edges(y,f,np)
  %> @brief this function applies smoothing function "f" to uniformly 
  %> distributed  vector "y". In order to avoid the problem with edges
  %> vector "y" is mirrored at the edges, with inversion, so value and
  %> first derivative is continuous
  %> @note nope, does not work, we should invert not realtively to a single edge
  %> point, but relatively to some average of the edge points, otherwise
  %> there may be a big discontinuity
  
  % so, let's try to find edge point. To make it simple let's take some
  % reasonable number of edge points
  y = y(:);
  n =numel(y);
  
  if ~exist('np','var') || isempty(np), np = max([16,n/50]); end
  
  c_left = AVP.linear(y(1:np));
  c_right = AVP.linear(y(end:-1:end-np));
  
  ym = [2*c_left(1)-y(end:-1:2);y;2*c_right(1)-y(end-1:-1:1)];
  yf = f(ym);
  ys = yf(numel(y)+1:2*numel(y));
  % keyboard
end

function test_script
 % lets make a noisy function  with a second derivative
 x = [1:1000]/1000;
 y = (x - 0.5).^2;
 yn = randn(size(y))*0.1 + y;
 [ys ym] = AVP.smooth_with_edges(yn,@smooth,20);
end
