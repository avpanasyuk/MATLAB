function o = rel_rms(x,y,dim)
  if ~exist('dim','var'), dim = 1; end
  o = AVP.squeeze(AVP.rms(x-y,dim)./sqrt(AVP.rms(x,dim).*AVP.rms(y,dim)));
end
