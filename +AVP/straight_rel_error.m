function [err, weight] = straight_rel_error(value,reference)
  weight = 1./reference;
  err = value./reference - 1;
end 
