%> @brief convert any variable into bytes (variable should not contain strings
%> anywhere, as they are variable length).
function bytes = something2bytes(x)
  bytes = []; 
  if numel(x) ~= 1,
    for n=1:numel(x),
      bytes = [bytes,AVP.CONVERT.something2bytes(x(n))];
    end
  else
    if isstruct(x)
      fn = fieldnames(x);
      for fi=1:numel(fn)
        bytes = [bytes,AVP.CONVERT.something2bytes(getfield(x,fn{fi}))];
      end
    else
      if iscell(x),
        bytes = [bytes,AVP.CONVERT.something2bytes(x{1})];
      else
        bytes = [bytes, AVP.CONVERT.to_bytes(x)];
      end
    end
  end
end

      
        
      
  
    