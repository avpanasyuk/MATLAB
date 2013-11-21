function grid = cell2grid(cell_x)
% creates n-dimentional grid non-uniform rectangular from the n-element cell array. Each element of
% the cell array is vector defining grid along this dimention. Returns grid
% as a 2-D array NumPoints X NumDimensions with points coordinates
ndim = numel(cell_x);
GridArr = cell([1,ndim]);
[GridArr{:}] =  ndgrid(cell_x{:});
GridArr = cat(ndim+1,GridArr{:});
sz = size(GridArr);
grid = reshape(GridArr,prod(sz(1:ndim)),sz(ndim+1));
end


