function [d,d2] = diff(y,x)
% diff on potentially non-uniform grid along the first dimension
% @retval d - first derivative
% @retval d2 - second derivative
if size(y,1) == 1, y = y.'; end
sz = size(y);
if sz(1) < 3, error('Too few points to calculate derivative'); end
y_ = reshape(y,sz(1),[]); % combine all the dims except of first
if ~exist('x','var'), x = [1:sz(1)].'; end
if size(x,2) ~= sz(2), x = repmat(x,1,sz(2)); end
dy = y_(2:end,:)-y_(1:end-1,:);
dx = x(2:end,:)-x(1:end-1,:);
d1 = dy./dx;
d = (dy(2:end,:)./dx(2:end,:).^2+dy(1:end-1,:)./dx(1:end-1,:).^2)./...
  (1./dx(2:end,:)+1./dx(1:end-1,:));
d = reshape([d1(1,:);d;d1(end,:)],sz);
if nargout > 1
  d2 = 2*(d1(2:end,1)-d1(1:end-1,:))./(dx(2:end,:)+dx(1:end-1,:));
  d2 = reshape([d2(1,:);d2;d2(end,:)],sz);
end
end

