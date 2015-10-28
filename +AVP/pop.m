function out = pop(x,n)
  %> poping byte sequences or typecast values from a given in advance array of bytes
  %> the array should be preset by calling this function with it as a parameter
  %> @example 
  %> AVP.pop(uint8([3 4 2 5]))
  %> AVP.pop('unit16'); AVP.pop('unit16'); 
  %> @param x
  %> - If a scalar is the number of bytes to pop, default 1.
  %> - if vector defines an array to pop bytes from
  %> - If scalar 0 then out is size of remaining array
  %> - if string - the type of value to pop, then
  %> @param n defines the number of values to pop, default 1. It maybe
  %    array, then it defines dimentions of output array
  
  
  persistent to_pop_from
  
  if nargin == 0, x = 1; end
  if isstr(x) % getting typecast value, x is type
    if ~exist('n','var'), n = 1; end
    if numel(find(size(n) ~= 1)) == 0
      out = typecast(AVP.pop(n*AVP.get_size_of_type(x)),x);
    else
      out = reshape(typecast(AVP.pop(prod(n)*AVP.get_size_of_type(x)),x),n);
    end
  else
    if numel(x) == 1      
      if x == 0, out = numel(to_pop_from);
      else
        if numel(to_pop_from) < x, error('Not enough bytes to pop from!'); end
        out = to_pop_from(1:x);
        to_pop_from = to_pop_from(x+1:end);
      end
    else
      to_pop_from = x;
      out = [];
    end
  end
end

