% sets line value
function set_line(obj,line,value)
putvalue(obj.parport.(line),value);
end
