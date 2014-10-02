%% REal FFT function. real part of return is cosine coeffs, imaginary - sine coeffs. 
% Last cosine coeff is in 1 position of imaginary, becuase there is end/2+1
% cos coeff and first sin coeff is always 0

function out = realfft(y)
coeffs = fft(y)/size(y,1);
rc = real(coeffs); ic = imag(coeffs);
out = complex(cat(1,rc(1,:,:,:),rc(2:end/2,:,:,:)+rc(end:-1:end/2+2,:,:,:)),...
    cat(1,rc(end/2+1,:,:,:),ic(end:-1:end/2+2,:,:,:)-ic(2:end/2,:,:,:))); 
end


