% REal FFT function. returns complex  vector with real part corresponding to cosines and
% imaginary to sines
% size of y should be even

function out = realfft(y)
  f = AVP.realfft0(y);
  out = complex(f(1:end/2,:,:,:),f(end/2+1:end,:,:,:));
end


