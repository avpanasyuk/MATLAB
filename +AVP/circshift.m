  function out = circshift(x, s)
      %> Shift signal x circularly by s samples.
			%> Difference from Signal Porcessing one is thats can be fractional.
      N = numel(x);
      k = [0:floor(N/2), -ceil(N/2)+1:-1];   % canonical FFT frequency bins
      out = real(ifft(fft(x(:)) .* exp(-1i*2*pi*s*k(:)/N)));
      out = reshape(out, size(x));
  end
