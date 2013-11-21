function out=vector(x,index)
	if nargin < 2, out = x(:); else out = x(index(:)); end
end
