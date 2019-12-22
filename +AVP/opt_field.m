
function opt_field(struct_name,field_name,default)
  %> if structure STRUCT_FIELD does not have a given field FIELD_NAME set
  %it to default value
  if ~evalin('caller',['exist(''', struct_name,''',''var'')'])
    assignin('caller',struct_name,struct());
  end
  if ~evalin('caller', ['AVP.isfield(', struct_name, ',''', field_name,''')'])
    % we can not use ASSIGNIN on structure field, so we have to go
    % through intermediate variable
     assignin('caller','opt_field_temp',default);
     evalin('caller',[struct_name, '.', field_name,...
       '= opt_field_temp; clear opt_field_temp']);
     clear
  end
end
