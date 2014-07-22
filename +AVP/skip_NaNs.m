function out = skip_NaNs( func, x )
%AVP.robust - when array x contains NaN runs array functions (like 'min' or
%'median') avoiding them. 
sz = size(x);

x = reshape(x,sz(1),prod(sz(2:end)));
out = NaN(1,size(x,2));
for colI = 1:size(x,2)
    out(colI) = func(x(isfinite(x(:,colI)),colI));
end
out = squeeze(reshape(out,[1,sz(2:end)]));
end

