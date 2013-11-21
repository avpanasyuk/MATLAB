% convert structure into a cell array with columns corresponding to all
% field names (including nested) and header row
% if structure field is a vector makes separate column for each element
% different from struct2cell because latter returns header field in the
% first row of the cell array
% if s is a struct array all resulting cell arrays are concatenated
function [c header] = struct2cell1(s)
% 
c = {}; header = {}; 
if numel(s) ~= 1,
  for ri=1:numel(s),
    [c_row header] = AVP.struct2cell1(s(ri));
    c = [c; c_row];
  end
else
  % going recursively through structure
  fn = fieldnames(s);
  for fi=1:numel(fn)
    f = [getfield(s,fn{fi})];
    if isstruct(f), 
      [cn hn] =  AVP.struct2cell1(f,N);
      header = [header, strcat([fn{fi} '.'],hn)];
      c = [c, cn];
    else
      N = numel(f);
      if N > 1,
        for ni=1:N,
          header{end+1} = [fn{fi} '{' int2str(ni) '}'];
          c{end+1} = f(ni);
        end
      else 
        header{end+1} = fn{fi};
        c{end+1} = f;
      end
    end
  end
end
end  