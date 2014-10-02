function out = skip_NaNs( func, x )
%AVP.robust - when array x contains NaN runs array functions (like 'min' or
%'median') avoiding them
sz = size(x);

x = reshape(x,sz(1),product(sz(2:end)))
out = NaN(1,size(x,2))
for colI = 1:size(x,2)
    out(ColI) = func(x(isfinite(x(:,colI)),colI));
end
out = reshape(out,sz(2:end));
end

