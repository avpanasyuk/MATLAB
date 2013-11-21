function field = getfield(s,name)
%+ differs from built-in in that it works with nested names
%-

[level0,name] = strtok(name,'.');
if isempty(name), % we got to the end of the name name
  field = getfield(s,level0);
else
  field = AVP.getfield(getfield(s,level0),name);
end
end
