function erase(var_name)
  %> deletes and cleans variable
  evalin('caller',['if exist(''' var_name ''',''var''), delete(' var_name ...
    '); clear(''' var_name '''); end']);
end