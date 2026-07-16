%> @file orderNpoly Fitting N order polinomial to 2*M+1 potentially 
%> non-equally spaced points points and
%> getting value at point M. This function returns filtered points.

function [yf, c] = orderNpoly(N,yi,xi)
  %> @param N - max polynomial degree
  if ~AVP.is_defined('xi'), xi=1:numel(yi); end
  
 % [pp,xx] = AVP.mesh(0:2*N,xi);
 [xx,pp] = AVP.mesh(xi,0:2*N);
 Xpowers = xx.^pp;
 X_sum = sum(Xpowers);
    
  A = [];
  for j=0:N
     A = [A;X_sum(j+1:j+N+1)];
     B(j+1) = sum(yi.*xi.'.^j);
  end
  
  c = A\B.';
  yf = Xpowers(:,1:N+1)*c;  
end

function test(t)
  tf = t;
  for fi=(fs+1)/2:numel(t)-(fs-1)/2
    p = BR_DET.orderNfilter(3,t(fi-(fs-1)/2:fi+(fs-1)/2));
    tf(fi) = p((fs+1)/2);
  end
  plot([t,tf])
  
 [pp,xx] = AVP.mesh(0:N,xi);
 Ni = numel(yi);
 if mod(Ni,2) == 0
   error('Numpoints should be odd!');
 end
 Xpowers = xx.^pp;

 pinv(Xpowers*Xpowers.')*Xpowers
 
 [u s v] = svd(Xpowers.'*Xpowers);
  
end


