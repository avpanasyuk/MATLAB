function x = zero_mean(x,dim)
if nargin < 2, dim = 1; end
sz = size(x);
dims = ones(1,numel(sz));
dims(dim) = sz(dim);
x = x - repmat(AVP.mean(x,dim),dims);
end
