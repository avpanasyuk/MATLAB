% linear regression
% minimize sum((y - x*c(2) - c(1))^2)
% sum(y) - sum(x)*c(2) - n*c(1) = 0; c(1) = (sum(y) - sum(x)*c(2))/n;
% sum(y*x) - sum(x^2)*c(2) - sum(x)*c(1) = 0;
% sum(y*x) - sum(x^2)*c(2) - sum(x)*sum(y)/n + sum(x)^2*c(2)/n = 0;
% c(2) = (sum(y*x) - sum(x)*sum(y)/n)/(sum(x^2) - sum(x)^2/n)
% dc2/dyi = (xi - sum(x)/n)/(sum(x^2) - sum(x)^2/n)
% dc1/dyi = 1;
function [c e fit]= linear(y,x,show),

n = numel(y);
if nargin < 2 || isempty(x), x = y; x(:)=1:n; end
if nargin < 3, show = []; end
sx = sum(x);
sx2 = sum(x.^2);
t =  sx2 - sx^2/n;
c(2) = (sum(y.*x) - sx*sum(y)/n)/t;
c(1) = (sum(y)*sx2 - sx*sum(y.*x))/n/t;
yf = c(2)*x + c(1);
if nargout > 1,
    e(2) = sqrt(sum(((y - yf).*(x - sx/n)/t).^2)/(n*(n-2)));
    e(1) = sqrt(sum(((y - yf).*(sx2 - sx*x)/t/n).^2)/(n*(n-2)));
end
fit = x*c(2)+c(1);
if ~isempty(show), 
   plot(x,y,'.g'); hold on; axis manual
   plot(x,fit,'-r'); hold off; axis auto
end
