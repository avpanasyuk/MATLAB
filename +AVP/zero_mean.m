function [x meanX] = zero_mean(x,dim)
%> @brief subtruct mean from data 
%> @param dim - dimension along which to calculate mean
%> @param x - any sized array 
if nargin < 2, dim = 1; end
sz = size(x);
dims = ones(1,numel(sz));
dims(dim) = sz(dim);
meanX = AVP.mean(x,dim);
x = x - repmat(meanX,dims);
end
