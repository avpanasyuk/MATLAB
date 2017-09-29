function out = complex_fun(fun,x,dim,varargin)
  %> @param fun - function fun(x,varargin{:})
  out = complex(fun(real(x),varargin{:}),...
    fun(imag(x),varargin{:}));
end