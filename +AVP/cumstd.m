function [out cummean] = cumstd(A,dim)
  % calculates cummulative std, along columns by default
  if ~exist('dim','var'), dim = 1; end
  sz = size(A);
  N = repmat((1:sz(1)).',[1,sz(2:end)]);
  S = cumsum(A,dim);
  cummean = S./N;
  Q = cumsum(A.^2,dim);
  out = (Q - S.*cummean)./N;
end