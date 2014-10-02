function out = ParRC(R)
  out = real(R)/(1-(imag(R)./real(R)).^2);
end
