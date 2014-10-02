%% inverse from realfft. 
%
function out = realifft(f)
% now we have to demangle coefficients
coeffs = cat(1,complex(real(f(1,:,:,:))*2,0),conj(f(2:end,:,:,:)),...
    complex(imag(f(1,:,:,:))*2,0),f(end:-1:2,:,:,:));
out = real(ifft(coeffs))*size(f,1);
end



