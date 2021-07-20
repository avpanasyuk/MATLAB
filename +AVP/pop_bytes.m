%>!!!!!!!!!!!!!!!! usage discouraged, use pop
function [out x] = pop_bytes(x,n)
out = x(1:n);
x = x(n+1:end);
end

