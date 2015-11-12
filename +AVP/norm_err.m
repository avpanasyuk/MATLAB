function out = norm_err(y1,y2)
  out = (y1-y2)./repmat(sqrt(AVP.rms(y1).*AVP.rms(y2)),size(y1,1),1);
end