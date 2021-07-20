function M = deriv_kernel(wing_size,max_order)
  %> calculates a kernal which produce a derivate matrix of width = 2*wing_size + 1 
  %> and maximum order = max_order. If n-th raw of the matrix is convolved
  %with a vector it produces n-1-th order derivative.
  %> with the vector
  %> @param wing_size - integer
  x = [0:max_order];
  M = [];
  for delta = -wing_size:wing_size
    M = [M; delta.^x./factorial(x)];
  end
  M = AVP.inv_svd(M.' * M)*M.';
  % M = (M.' * M)\M.';
end