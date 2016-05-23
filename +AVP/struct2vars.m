%> assigns fields of the struct into variables with the same name
%> @param s - structurs to unpack
function struct2vars(s)
  fn = fieldnames(s);
  for fi=1:numel(fn)
    assignin('caller',fn{fi},s.(fn{fi}));
  end
end