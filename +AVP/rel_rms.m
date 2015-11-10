function o = rel_rms(x,y)
  o = AVP.squeeze(AVP.rms(x-y)./sqrt(AVP.rms(x).*AVP.rms(y)));
end
