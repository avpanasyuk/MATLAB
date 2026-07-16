%> @param exclude_fields - cell array of field names not to convert to
%> function
function S = obj2struct(a,exclude_fields,S)
  if nargin < 3,
    S = struct;
    if nargin < 2
      exclude_fields = {};
    end
  end
  
  fn = fields(a);
  for fi=1:numel(fn)
    if ~any(strcmp(fn{fi},exclude_fields))
      S.(fn{fi}) = a.(fn{fi});
    end
  end
end
