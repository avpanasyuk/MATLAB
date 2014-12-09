function C = mat_prod(A,B,dimA,dimB)
%> multiplies multidimensional array along selected dimensions
if nargin < 4 || isempty(dimB), dimB = 1; end
if nargin < 3 || isempty(dimA), dimA = 2; end

SzA = size(A); SzB = size(B);
if SzA(dimA) ~= SzB(dimB)
  error('Can not multiply!');
end
RdimA = [1:ndims(A)] ~= dimA;
RdimB = [1:ndims(B)] ~= dimB;


if ndims(A) > 2, 
  A = permute(A,[find(RdimA),dimA]);
  A = reshape(A,[],SzA(dimA));
end
if ndims(B) > 2, 
  B = permute(B,[dimB,find(RdimB)]);
  B = reshape(B,SzB(dimB),[]);
end

C = reshape(A*B,[SzA(RdimA) SzB(RdimB)]);
end
