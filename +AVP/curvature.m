function c = curvature(y,x)
% diff on potentially non-uniform grid along the first dimension
sz = size(y);
if sz(1) < 3, error('Too few points to calculate derivative'); end
if ~exist('x','var'), x = [1:sz(1)].'; end
[d1,d2] = AVP.diff(y,x);
c = (1+d1.^2).^1.5./smooth(d2,3);
end

 
  
