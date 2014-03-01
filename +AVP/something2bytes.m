% convert structure into a cell array with columns corresponding to all
% field names (including nested). Top row is a header
% S can be a 2D matrix of structures. 
function bytes = something2bytes(x)
  bytes = []; 
  if numel(x) ~= 1,
    for n=1:numel(x),
      bytes = [bytes,AVP.something2bytes(x(n))];
    end
  else
    if isstruct(x)
      fn = fieldnames(x);
      for fi=1:numel(fn)
        bytes = [bytes,AVP.something2bytes(getfield(x,fn{fi}))];
      end
    else
      if iscell(x),
        bytes = [bytes,AVP.something2bytes(x{1})];
      else
        bytes = [bytes, AVP.to_bytes(x)];
      end
    end
  end
end

      
        
      
  
    