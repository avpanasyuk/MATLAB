function out = vars2struct(varargin)
for ni=1:nargin
  out.(varargin{ni}) = evalin('caller',varargin{ni});
end