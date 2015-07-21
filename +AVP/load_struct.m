function load_struct(s)
%> assigns fields of a structure to workspace variables with the same names
for n = fieldnames(s)'
  name = n{1};
  value = s.(name);
  assignin('caller',name,value);
end
end
