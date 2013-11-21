% convert structure into a cell array with columns corresponding to all
% field names (including nested). Top row is a header
% S can be a 2D matrix of structures. 
function c = struct2cell(s)
  c = {}; 
  if ~isstruct(s), error('s is not a structure'); end
  % going recursively through structure
  fn = fieldnames(s);
  for fi=1:numel(fn)
    f = getfield(s,fn{fi});
    if isstruct(f), 
      cn =  AVP.struct2cell(f);
      cn(1,:) = strcat([fn{fi} '.'],cn(1,:)); % corrected nested names
      c = [c, cn];
    else
      c{1,end+1} = fn{fi};
      % c{2:numel(f)+1,end} = f(:);
       for ci=1:numel(f), c{ci+1,end} = f(ci); % no other assignment works
    end
  end
end  