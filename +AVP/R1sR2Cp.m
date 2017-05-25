function [R1,R2,C] = R1sR2Cp(Iw1,Iw2,Rw2,w1,w2)
  % calculates values of R1,R2 and C with R1 serially connected to parallel
  % R2 and C from total impedance values:
  % @param Iw1 - imaginary part of Z on higher freq w1
  % @param Iw2 - imaginary part of Z on lower freq w2
  % @param Iw2 - real part of Z on lower freq
  
  Z = 1/w1/w2./sqrt(Iw1.*Iw2*(w1/w2+w2/w1)-Iw2.^2-Iw1.^2);
  
  % R1 = w1*Z.*Iw2.*(Iw2*w2-Iw1*w1)+Rw2;
  R2 = Z.*Iw2.*Iw1*(w1^2-w2^2);
  C = (Iw1*w2-Iw2*w1)./(Iw1.*Iw2*(w1^2-w2^2));
  R1 = Rw2 - R2./(1+(w2*R2.*C).^2);
end


% Zf = @(w,R1,R2,C) R1+(R2/(1+i*w*R2*C))
% Zl = Zf(1000*2*pi,100,2000,200e-12)
% Zh = Zf(50000*2*pi,100,2000,200e-12)
% [R1,R2,C] = R1sR2Cp(imag(Zh),imag(Zl),real(Zl),50000*2*pi,1000*2*pi)
