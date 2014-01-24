function out=mean(x,varargin)
  f = isfinite(x); 
  x(~f)=0;
  out = sum(x,varargin{:})./sum(f,varargin{:});
end
