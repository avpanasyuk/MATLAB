%! If we have a matrix [num samples, num vars]  of independent variables
%! and we want to create matrix with cross-products of variables up to n
%! degree. This function does it.
%! @param X = [Num samples, Num vars] matrix
%! @param n = number of variables in an each product
%! @param do_lower - include lower powers in the resulting matrix as well
function [Xcross Inds] = n_cross_product(X,n,do_lower)
  Inds = AVP.n_cross_product_indexes(1:size(X,2),n);
  Xcross = prod(reshape(X(:,Inds(:)),[],size(Inds,1),n),3);
  if exist('do_lower','var') && do_lower
    for ni = n-1:-1:1
      [X1 Inds1] = AVP.n_cross_product(X,ni);
      Xcross = [X1,Xcross];
      Inds = [[Inds1,zeros(size(Inds1,1),size(Inds,2)-size(Inds1,2))];...
        Inds];
    end
  end
end
