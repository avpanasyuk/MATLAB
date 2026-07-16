function out = typecast( x,type )
% standard typecast takes only vector as a first argument
% this one takes anything and does typecast by columns
Sz = num2cell(size(x));
if ischar(x), x = uint8(x); end
out = reshape(typecast(x(:),type),[],Sz{2:end});
end

