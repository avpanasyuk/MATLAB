% convert structure into a cell array with columns corresponding to all
% field names (including nested). Top row is a header
% S can be a 2D matrix of structures. 
function [x, bytes] = bytes2something(bytes,x)
  if numel(x) ~= 1,
    for n=1:numel(x),
      [x(n), bytes] = AVP.bytes2something(bytes,x(n));
    end
  else
    if isstruct(x)
      fn = fieldnames(x);
      for fi=1:numel(fn)
        [t, bytes] = AVP.bytes2something(bytes,getfield(x,fn{fi}));
        x = setfield(x,fn{fi},t);
      end
    else
      if iscell(x),
        [x{1} bytes] = AVP.bytes2something(bytes,x{1});
      else
        if isreal(x), 
          n = numel(typecast(x,'uint8')); % number of bytes in value
          x = typecast(bytes(1:n),class(x));
          bytes = bytes(n+1:end);
        else
          [re, bytes] = AVP.bytes2something(bytes,real(x));
          [im, bytes] = AVP.bytes2something(bytes,imag(x));
          x=complex(re,im);
        end
      end
    end
  end
end

      
        
      
  
    