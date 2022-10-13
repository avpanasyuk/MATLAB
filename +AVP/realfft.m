% REal FFT function. returns complex  vector with real part corresponding to cosines and
% imaginary to sines
% size of y should be even

function out = realfft(y)
  f = AVP.realfft0(y);
  out = complex(f(1:end/2,:,:,:),f(end/2+1:end,:,:,:));
end


function test
  x = [1:64].'/64*2*pi;
  f = AVP.realfft(3*sin(5.7*x) + 7*cos(8.2*x));
  plot(abs(f))
  set(gca,'XLim',[0,20])
end