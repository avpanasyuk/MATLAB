function Inds = except(N,inds_to_except)
  Inds = 1:N;
  Inds(inds_to_except) = [];
end