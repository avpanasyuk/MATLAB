function M = deriv_kernel(wing_size,max_order,varargin)
  %> calculates a kernal which produce a derivate matrix of width = 2*wing_size + 1
  %> and maximum order = max_order. If n-th raw of the matrix is convolved
  %with a vector it produces n-1-th order derivative.
  %> with the vector
  %> @param wing_size - integer
  %> @param where - at what point the derivative is calculated - if 1 (default) at the center
  %>                if 0 at the first point, 2 is the last point
  AVP.opt_param('where',1);

  x = [0:max_order];
  M = [];
  switch where
    case 1
      for delta = -wing_size:wing_size
        M = [M; delta.^x./factorial(x)];
      end
    case 0
      for delta = 0:(wing_size-1)
        M = [M; delta.^x./factorial(x)];
      end
    case 2
      for delta = (wing_size-1):-1:0
        M = [M; (-delta).^x./factorial(x)];
      end
    otherwise
      error('Wrong "where"!')
  end
  M = AVP.inv_svd(M.' * M)*M.';
  % M = (M.' * M)\M.';
end