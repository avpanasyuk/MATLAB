%! If we have a matrix [num samples, num vars]  of independent variables
%! and we want to create matrix with cross-products of variables up to n
%! degree. This function does it. IT DOES NOT INSERT UNITY ROW
%! @param X = [Num samples, Num vars] matrix
%! @param n = number of variables in an each product
%! @param do_lower - include lower powers in the resulting matrix as well
%! @retval Inds = [n,Num var prods] for each column gives indexes of
%! input vars combined for this term or 0 if DO_LOWER is active and the
%! order of the term is less then N
%! @retval Xcross = [num samples,Num var prods] - cross products
function [Xcross Inds] = n_cross_product(X,n,do_lower)
  if exist('do_lower','var') && do_lower
    [Xcross Inds] = AVP.n_cross_product([ones(size(X,1),1),X],n);
    Xcross = Xcross(:,2:end);
    Inds = Inds(2:end,:) - 1;
  else
    Inds = AVP.n_cross_product_indexes(1:size(X,2),n);
    Xcross = prod(reshape(X(:,Inds(:)),[],size(Inds,1),n),3);
  end
end
