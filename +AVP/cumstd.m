function out = cumstd(A,dim)
  if ~exist('dim','var'), dim = 1; end
  sz = size(A);
  N = repmat((1:size(A,1)).',[1,sz(2:end)]);
  S = cumsum(A,dim);
  Q = cumsum(A.^2,dim);
  out = (Q - S.^2./N)./N;
end