function out = complex_fun(fun,x,dim,varargin)
  %> @param fun - function fun(x,dim, ....)
  sz = size(x);
  sz(dim) = [];
  out = reshape(complex(fun(real(x),dim),fun(imag(x),dim)),[sz,1,1]);
end