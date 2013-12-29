function cplot(y,x)
  if nargin < 2, x = [1:numel(y)]; end
  plot(x,real(y),'r-+',x,imag(y),'b-+');
end
