function X = find_0_div2(input_fun,output_fun,range,tol)
  % finds 0 by division by two
  if ~exist('tol','var') tol=1.0; end
  input_fun(range(1));
  Y(1)=output_fun();
  input_fun(range(2));
  Y(2)=output_fun();
  if sign(Y(1)) == sign(Y(2)),
    error('find_0_div2:NoSolution','No solution: %d->%d, %d->%d',...
      range(1),Y(1),range(2),Y(2));
  end
  while abs(range(1) - range(2)) > tol,
    NewX = (range(1)+range(2))/2;
    input_fun(NewX);
    NewY = output_fun();
    if sign(NewY) == sign(Y(1))
      range(1) = NewX;
      Y(1) = NewY;
    else
      range(2) = NewX;
      Y(2) = NewY;
    end
  end
  X = (range(1)+range(2))/2;
end

