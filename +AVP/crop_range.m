function [bounds,x] = crop_range(x,part_to_strip),
% function crop_range(x,part_to_strip),
% returns margins inside which most of the values of X are lyeing,
% stripping PART_TO_STRIP part of outliers from the both ends

if nargin == 1, part_to_strip=[0.001 0.001]; end
if numel(part_to_strip) == 1, part_to_strip = [part_to_strip part_to_strip]; end

% remove NaNs
x_ = x(:);
x_ = x_(find(isfinite(x_)));
Sorted = sort(x_);
sz = numel(x_);
bounds(1) = Sorted(ceil(max([part_to_strip(1)*sz(1) 1])));
bounds(2) = Sorted(sz(1) + 1 - ceil(max([part_to_strip(2)*sz(1) 1])));
if nargout > 1
  x(x < bounds(1)) = bounds(1);
  x(x > bounds(2)) = bounds(2);
end
end


