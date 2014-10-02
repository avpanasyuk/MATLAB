function cplot(y,x)
  y = y(:); 
  if nargin < 2, x = [1:size(y,1)]; else x = x(:); end
  plot(x,real(y),'r-.+',x,imag(y),'b-.+');
  if ~ishold, held = 1; hold on; end
  plotyy(x,abs(y),x,angle(y));
  if exist('held'), hold off; end
end
