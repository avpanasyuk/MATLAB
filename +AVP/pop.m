function out = pop(x,n)
%> FIXME: THIS IS A WEIRD FUNCTION, USE "FIFO" CLASS INSTEAD
%> optimized version of "pop" in that it does not create partial copies of the   
%> initial array, which may be very memory consuming. Optionally it uses 
%> "memmapfile" to avoid copying big data
%> poping byte sequences or typecast values from a given in advance array of bytes
%> @example
%> AVP.pop(uint8([3 4 2 5]))
%> AVP.pop('uint16'); AVP.pop('uint16',1);
%> @param x
%>   ONE OF THE NEXT TWO CALLS SHOULD BE USED BEFORE ANY
%>   OTHER CALL
%> - if is vector it defines an array to pop bytes from. 
%> - if is a string & n == 0 the value is the filename of file to
%>   pop bytes from
%>
%> - If is a scalar is the number of bytes to pop, default 1.
%> - If parameter is absent then out is size of remaining array
%> - if string & n > 0 the type of value to pop, then
%> @param n defines the number of values to pop, default 1. It maybe
%>    array, then it defines dimentions of output array. If
%>    it is n < 1 it is used to specify different x options 

persistent to_pop_from CurI

if nargin == 0, out = numel(to_pop_from) - CurI + 1;
else
  if isstr(x) % getting typecast value, x is type
    if ~exist('n','var'), n = 1; else 
      if n == 0 % setup a file to read from, "x" is the file name
        m = memmapfile(x);
        to_pop_from = m.Data;
        CurI = 1;
        out = [];
        return
      else n = double(n); 
      end
    end
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
  else % "x" is not string
    x = double(x);
    if numel(x) == 1
        if numel(to_pop_from) - CurI + 1 < x, error('Not enough bytes to pop from!'); end
        out = uint8(to_pop_from(CurI:CurI + x - 1));
        CurI = CurI + x;
    else % setup a byte array to read from
      to_pop_from = x;
      CurI = 1;
      out = [];
    end
  end
end
end

