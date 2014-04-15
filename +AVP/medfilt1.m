function medfilt1(x)
  ndim = numel(size(x));
  permute(repmat(x,[ones(1, ndim), 3]),[ndim+1 1:ndim])
end