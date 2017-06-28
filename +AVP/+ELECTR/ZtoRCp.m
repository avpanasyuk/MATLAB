function [R,wC] = ZtoRCp(Z)
  Zsqr = AVP.abs_sqr(Z);
  R = Zsqr./real(Z);
  wC = - imag(Z)./Zsqr; 
end