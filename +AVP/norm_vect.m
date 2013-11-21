function out = norm_vect(v)
% normalize the length of vectors [m,n] where n is space dimentioness
sz = size(v);
out = v./repmat(sqrt(sum(v.*v,2)),[1,sz(2)]);
end
