% fit function if we do not have toolboxes
function c_min = basic(func_of_c_x, y, c0, varargin)
	AVP.opt_param('x',[1:numel(y)].' - 1,1);
	subplot(2,1,1)
	plot([y(:),func_of_c_x(c0,x(:))])
	c_min = fminsearch(@(c) sum((func_of_c_x(c,x) - y).^2), c0, varargin{:});
	subplot(2,1,2)
	plot([y(:),func_of_c_x(c_min,x(:))])	
end