
function opt_field(struct_name,field_name,default)
  %> if structure STRUCT_FIELD does not have a given field FIELD_NAME set
  %it to default value
  if ~evalin('caller', ['isfield(', struct_name, ',''', field_name,''')'])
     assignin('caller',[struct_name, '.', field_name],default);
  end
end
