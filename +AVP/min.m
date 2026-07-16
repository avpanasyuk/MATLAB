function [value, varargout] = min(x,varargin)
  %> returns array subscripts instead of linear index
  [value, ind] = min(x,varargin{:});
  [varargout{:}] = ind2sub(size(x),ind);
end