% REal FFT function. returns real vector with indexes 1:n/2+1 correspond to cosines and
% n/2+2:end to sines
% size of y should be even

function out = realfft(y)
  f = AVP.realfft0(y);
  out = complex(f(1:end/2,:,:,:),f(end/2+1:end,:,:,:));
end


