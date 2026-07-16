function [err, weight] = rel_error(x1,x2)
  % I like this approach, range -2*sqrt(2)..2*sqrt(2)
  weight = 1./sqrt((x1.*conj(x1)+x2.*conj(x2))/2);
  err = (x1-x2).*weight;
end
