function out = pop(x,n)
%> poping byte sequences or typecast values from a given in advance array of bytes
%> the array should be preset by calling this function with it as a parameter
%> @example
%> AVP.pop(uint8([3 4 2 5]))
%> AVP.pop('uint16'); AVP.pop('uint16',1);
%> @param x
%> - if vector defines an array to pop bytes from. SHOULD BE USED BEFORE
%>   OTHER CALLS
%> - If a scalar is the number of bytes to pop, default 1.
%> - If parameter is absent then out is size of remaining array
%> - if string - the type of value to pop, then
%> @param n defines the number of values to pop, default 1. It maybe
%    array, then it defines dimentions of output array

persistent to_pop_from

if nargin == 0, out = numel(to_pop_from);
else
  if isstr(x) % getting typecast value, x is type
    if ~exist('n','var'), n = 1; else n = double(n); end
    x = x(:).'; % make sure it is string 
    if numel(find(size(n) ~= 1)) == 0
      if strcmp(x,'char')
        out = char(AVP.pop(n*AVP.size_of_type('int8')));
      else
        out = typecast(AVP.pop(n*AVP.size_of_type(x)),x);
      end
    else
      if strcmp(x,'logical')
        out = reshape(typecast(AVP.pop(prod(n)*AVP.size_of_type(x)),'uint8'),n(:).');
      else
        out = reshape(typecast(AVP.pop(prod(n)*AVP.size_of_type(x)),x),n(:).');
      end
    end
  else
    x = double(x);
    if numel(x) == 1
        if numel(to_pop_from) < x, error('Not enough bytes to pop from!'); end
        out = uint8(to_pop_from(1:x));
        to_pop_from = to_pop_from(x+1:end);
    else
      to_pop_from = x;
      out = [];
    end
  end
end
end

