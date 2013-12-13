function x=nonan(x),
	x = x(find(isfinite(x)));
end
	