function out=checkXOR(x,type)
  %> @param type - sting, only unsigned
  if ~exist('type','var'), type = class(x(1)); end
  out = typecast(cast(-1,type(2:end)),type); % generate 1111111...
  % we select 111111 as start value so sequence of 0s does not
  % create valid checkXOR value
  x = typecast(x,type);
  for n=1:numel(x), out = bitxor(out,x(n)); end
end
