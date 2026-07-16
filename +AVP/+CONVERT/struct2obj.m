%> @param a got to be handle class. Only already existing fields are
%> assigned
function struct2obj(a,S)
  fn = fields(a);
  fnS = fields(S);
  for fi=1:numel(fn)
    if ~any(strcmp(fn{fi},fnS))
      a.(fn{fi}) = S.(fn{fi});
    end
  end
end