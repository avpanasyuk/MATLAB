function out=find_zeros(v),
% function out=find_zeros(v),
% find all places where vector v crosses 0 and returns precise positions
% using linear interpolation.

ZeroI = find((v(1:end-1) < 0 & v(2:end) >= 0) | ...
    (v(1:end-1) > 0 & v(2:end) <= 0)); 
out = ZeroI - v(ZeroI)./(v(ZeroI+1)-v(ZeroI));
end

