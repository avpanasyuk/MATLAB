function err = norm_rms_diff(data,fit,dim)
  %> Returns normalized RMS error, where error at each point is normalized to be in +-1 range.
  %> It works with complex data and fit. 
  if ~AVP.is_defined('dim'), dim = 1; end
  if isreal(data) & isreal(fit)
    err = sqrt(1 - mean(2*data.*fit./(data.^2 + fit.^2),dim));
  else
    delta = data - fit;
    err = sqrt(mean(2*delta.*conj(delta)./(data.*conj(data)+fit.*conj(fit)),dim));
%     err = (sum((delta.*conj(delta)).^(degree/2),dim)./...
%       sum(((data.*conj(data)+fit.*conj(fit))/2).^(degree/2),dim)).^(1/degree);
  end
end

