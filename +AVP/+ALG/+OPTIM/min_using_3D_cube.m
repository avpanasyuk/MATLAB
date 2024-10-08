function [Pos, c] = min_using_3D_cube(D27)
  %> I need new optimization algorithm, where a lot of points are calculated
  %> first, and then a new guess made. Lets try to do it on a basis of
  %> 3D. we will fit 27 points in the cube with 3d hyperbola,
  % defined by 10 parameters

  % c1 + c2*x +c3*y + c4*z + c5*x^2 + c6*y^2 + c7*z^2 + c8*x*y + c9*x*z +
  % c10*y*z
  % so we have 27 equations, D are data points
  % A * c = D, lets construct A

  persistent InvA

  if isempty(InvA)
    % points along each dimension are [-1,0,1], we will multiply by step any
    % time

    Ndim = 3;
    Carr = {[-1,0,1]};
    Carr = repmat(Carr,Ndim,1);

    Cout = AVP.mesh_cell(Carr{:});
    % it is not easy to go with variable number of dimensions, because I do not know how
    % to lets start with
    % 3 fixed

    [x,y,z] = deal(Cout{:});
    x = x(:); y = y(:); z = z(:);

    % Ok, so we have 27 points of data, and we are going to fit them with
    Ones = ones(3*ones(1,Ndim));
    A = [Ones(:), x, y, z,  x.^2, y.^2, z.^2, x.*y, x.*z, y.*z];
    InvA = pinv(A);
  end

  c = InvA*D27(:); % looks correct, how to get the position of minimum from c

  % c2 + 2*c5*x + c8*y + c9*z = 0
  % c3 + 2*c6*y + c8*x + c10*z = 0
  % c4 + 2*c7*z + c9*x + c10*y = 0
  Pos = - pinv([[2*c(5),c(8),c(9)];...
    [c(8),2*c(6),c(10)];...
    [c(9),c(10),2*c(7)]])*c([2:4]);
  % correct
end % min_using_3D_cube

function Test
  % lets see how it work. Say, we have function

  TestF = @(x,y,z) 3 + (x+y-0.3).^2 + (x+2*z-0.1).^2 + (y-z-0.2).^2;
  c = InvA*TestF(x,y,z); % looks correct, how to get the position of minimum from c
end