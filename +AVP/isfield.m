function itis = isfield(s,field)
%+ differs from built-in in that it works with nested fields
%-

[level0,field] = strtok(field,'.');
if isempty(field), % we got to the end of the field name
  itis = isfield(s,level0);
else
  itis = AVP.isfield(getfield(s,level0),field);
end
end
