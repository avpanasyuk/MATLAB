%> @file orderNpoly_kernel_regular Fitting N order polinomial to 2*M+1 regiularly speced points and
%> getting value at M. This function return convolution kernel

function kern = orderNpoly_kernel_regular(Order,Npoints)
  %> @param Order - max polynomial degree
  %> @param Npoints - width of convolution kernel
  
 [pp,xx] = AVP.mesh(0:Order,[1:Npoints] - (Npoints+1)/2);
 if mod(Npoints,2) == 0
   error('Numpoints should be odd!');
 end
 Xpowers = xx.^pp;

 [u s v] = svd(Xpowers*Xpowers.'); 
 d = 1./diag(s);
 d(d > 1) = 0;
 inv = v*diag(d)*u.';
  
 %inv = pinv(Xpowers*Xpowers.');
  
 a = inv*Xpowers;
 
 kern = a(1,:);
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


