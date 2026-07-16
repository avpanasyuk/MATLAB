% differs from the system fread in that it returns the same type as read
function out = fread(f,size,prec,varargin)
  if ~AVP.is_defined('size'), size = [1,1]; end
  if ~AVP.is_defined('prec'), prec = 'uint8'; end
  out = fread(f,size,['*', prec],varargin{:});
end