%% inverse from realfft0. 
%
function out = realifft0(f)
% now we have to demangle coefficients
coeffs = cat(1,complex(f(1,:,:,:)*2,0),...
  complex(f(2:end/2,:,:,:),-f(end/2+2:end,:,:,:)),...
  complex(f(end/2 + 1,:,:,:)*2,0),...
  complex(f(end/2:-1:2,:,:,:),f(end:-1:end/2+2,:,:,:)));
out = real(ifft(coeffs))*size(f,1)/2;
end



