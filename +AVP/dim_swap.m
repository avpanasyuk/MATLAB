function x = dim_swap(x,dim_pairs)
%> does perure swapping dimentions according to dim_pairs
%> @param dim_pairs = [:,2] - pairs of dimentions to be swapped

dimI = 1:ndims(x);
for PairI = 1:size(dim_pairs,1)
    dimI(dim_pairs(PairI,:)) = dimI(dim_pairs(PairI,2:-1:1));
end
x = permute(x,dimI);
end
