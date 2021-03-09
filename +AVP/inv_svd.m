function Inv = inv_svd(M, varargin)
  [U,S,V] = svd(M);
  SVs = diag(S);
  Last = find(SVs/SVs(1) < 10*eps,1,'first');
  if ~isempty(Last)
    SVs = SVs(1:Last);
    V = V(:,1:Last);
    U = U(:,1:Last);
  end  
  Inv = V*diag(1./SVs)*U.';    
end