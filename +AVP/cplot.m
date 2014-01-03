function cplot(y,x)
  if nargin < 2, x = [1:numel(y)]; end
  plot(x,real(y),'r-.+',x,imag(y),'b-.+');
  if ~ishold, held = 1; hold on; end
  plotyy(x,abs(y),x,angle(y));
  if exist('held'), hold off; end
end
