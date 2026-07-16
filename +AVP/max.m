function [value, varargout] = max(x,varargin)
  %> returns array subscripts instead of linear index
  [value, ind] = max(x,varargin{:});
  [varargout{:}] = ind2sub(size(x),ind);
end