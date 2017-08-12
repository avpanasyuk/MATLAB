function erase(var_name)
  %> deletes and cleans variable
  evalin('caller',['if exist(''' var_name ''',''var'') && isobject(' var_name '), delete(' var_name ...
    '); clear(''' var_name '''); end']);
end