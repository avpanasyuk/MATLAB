function c = curvature_via_diff(y,x)
% diff on potentially non-uniform grid along the first dimension
% correct almost everywhere except vertical pieces
% "curvature" is better, This one is left here to remember analog formula.
y = y(:); x = x(:);
sz = size(y);
if sz(1) < 3, error('Too few points to calculate derivative'); end
if ~exist('x','var'), x = [1:sz(1)].'; end
[d1,d2] = AVP.diff(y,x);
c = smooth(d2,3)./(1+d1.^2).^1.5;
end

 
  
