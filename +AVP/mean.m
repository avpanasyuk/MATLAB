function out=mean(x,varargin)
  %> differnse from standard mean in that is ignores ~finite elements
  f = isfinite(x); 
  x(~f)=0;
  out = sum(x,varargin{:})./sum(f,varargin{:});
end
