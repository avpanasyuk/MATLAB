function out = w_func4fft(x)
  n = numel(x);
  out = [x(1:n/2+1),conj(x(n/2:-1:2))];
end
