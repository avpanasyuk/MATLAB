function [o, Mean] = rms(x,dim,around_mean)
  sz = size(x);
  if ~exist('dim','var') || isempty(dim)
    dim = 1;
  end
  Mean = mean(x,dim);
  if AVP.is_true('around_mean')
    x = x - AVP.repmat(Mean, sz(dim), dim);
  end
  o = sqrt(mean(x.*conj(x),dim)); 
end
