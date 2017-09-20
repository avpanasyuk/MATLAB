function out = plotc(d,varargin)
  out = plot(real(d),imag(d),varargin{:});
end