function out = crop_range(x,part_to_strip),
% function crop_range(x,part_to_strip),
% returns margins inside which most of the values of X are lyeing,
% stripping PART_TO_STRIP part of outliers from the both ends

if nargin == 1, part_to_strip=[0.01 0.01]; end
if numel(part_to_strip) == 1, part_to_strip = [part_to_strip part_to_strip]; end

% remove NaNs
x = x(:);
x = x(find(isfinite(x)));
Sorted = sort(x);
sz = numel(x);
out(1) = Sorted(ceil(max([part_to_strip(1)*sz(1) 1])));
out(2) = Sorted(sz(1) + 1 - ceil(max([part_to_strip(2)*sz(1) 1])));
end


