%! If we have a matrix [num samples, num vars]  of independent variables
%! and we want to create matrix with cross-products of variables up to n
%! degree. This function helps providing a matrix of variable indexes to
%! combine for each summation term
%! @param v = vector 1:Nvar
%! @retval Xcross [Num combinations, Num vars in products] array of indexes
function y = n_cross_product_indexes(v, n)
   if n == 1
      y = v(:);
   else
      v = v(:);
      y = [];
      m = length(v);
      if m == 1
         y = zeros(1, n);
         y(:) = v;
      else
         for i = 1 : m
         y_recr = AVP.n_cross_product_indexes(v(i:end), n-1);
         s_repl = zeros(size(y_recr, 1), 1);
         s_repl(:) = v(i);
         y = [ y ; s_repl, y_recr ];
         end
      end
   end

% function XcrossInds = n_cross_product_indexes(Nvar,n)
%   if n == 1, XcrossInds = [1:Nvar].'; 
%   else
%     XcrossInds = AVP.n_cross_product_indexes(Nvar-1,n-1); 
%     NewCol = repmat([1:Nvar],size(XcrossInds,1),1);
%     XcrossInds = [NewCol(:),repmat(XcrossInds,Nvar,1)];
%   end
% end  
