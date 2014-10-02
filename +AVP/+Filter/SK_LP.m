function TrF = SK_LP(w,R1,R2,C1,C2,Iw,Ig) 
  if nargin < 7, Ig = 0; % Ig = 1 /Gdc 
    if nargin < 6, Iw = 0; % Iw = Gdc/GBP
    end
  end
  
TrF = 1./(C1*C2*Iw*R1*R2*i^3*w.^3+...
  (C1*C2*Ig*R1*R2*i^2+C1*C2*R1*R2*i^2+C1*Iw*R1*i^2+C1*Iw*R2*i^2+C2*Iw*R1*i^2)*w.^2+...
  (C1*Ig*R1*i+C1*Ig*R2*i+C2*Ig*R1*i+C1*R1*i+C1*R2*i+Iw*i)*w+Ig+1);
end