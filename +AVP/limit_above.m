function x = limit_above(x,limit),
	x(find(x > limit)) = limit;
end