function [o, Mean] = rms(x,dim,around_mean)
  sz = size(x);
  if ~exist('dim','var') || isempty(dim), dim = find(sz~=1,1,'first'); end
  Mean = mean(x,dim);
  if exist('around_mean','var') && around_mean
    x = x - AVP.repmat(Mean, sz(dim), dim);
  end
  o = sqrt(mean(x.*conj(x),dim)); 
end
