function out = shaped_subscripts( Array, Indexes )
%There is idiocy in MATLAB that it is inconsistent when one dimention of
%array comes 1. I was to have result of indexing array to be the same shape
%as indexes. I have to write a functino for this.
out = reshape(Array(Indexes(:)),size(Indexes));
end

