% get line value
function res = get_line(obj,line)
res = getvalue(obj.parport.(line));
end
