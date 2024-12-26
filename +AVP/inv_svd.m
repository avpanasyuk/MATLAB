function Inv = inv_svd(M, varargin)
  %> inverting matrix M while keeping it stable by removing SVs too small 
  AVP.opt_param('MinRelSV',0.01);

  [U,S,V] = svd(M,"econ");
  SVs = diag(S);
  InvSVs = 1./SVs;
  InvSVs(SVs < SVs(1)*MinRelSV) = 0;
  Inv = V*diag(InvSVs)*U.';    
end