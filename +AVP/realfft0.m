% REal FFT function. returns real vector with indexes 1:n/2+1 correspond to cosines and
% n/2+2:end to sines. CAN NOT BE USED FOR CONVOLUTION, use REALFFT for this
% size of y should be even

function out = realfft0(y)
coeffs = fft(y)/size(y,1);
rc = real(coeffs); ic = imag(coeffs);
out = cat(1,rc(1,:,:,:),rc(2:end/2,:,:,:)+rc(end:-1:end/2+2,:,:,:),...
    rc(end/2+1,:,:,:),ic(end:-1:end/2+2,:,:,:)-ic(2:end/2,:,:,:)); 
end


