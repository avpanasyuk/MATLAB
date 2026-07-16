function x = insert_dim(x,dimI,sz)
  x = AVP.insert_unity_dim(x,dimI);
  if AVP.is_defined('sz')
    x = AVP.repmat(x,sz,dimI);
  end
end