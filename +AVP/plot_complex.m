function plot_complex(y,x)
  y = y(:); 
  if nargin < 2, x = [1:size(y,1)]; else x = x(:); end
  plot(x,real(y),'r-.+',x,imag(y),'b-.+');
  held = ishold;
  if ~held, hold on; end
  plotyy(x,abs(y),x,angle(y));
  if ~held, hold off; end
end
