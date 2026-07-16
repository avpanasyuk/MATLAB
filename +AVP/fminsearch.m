%> the issue with matlab FMINSEARCH is that there is no control of the 
%> initial step, it is always +5% which may be not well suited. 
%> So, to control step, we can add ADD to x0, and then FMINSEARCH will
%> make ABS_STEP = (X0 + ADD)*0.05 = STEP0, so ADD = STEP0/0.05 - X0
%> we run FMINSEARCH twice, for all positive and all negative steps, and
%> select best
 
function [x,fval] = fminsearch(fun,x0,step0,options)
  if ~AVP.is_defined('options'), options = optimset(); end
  if ~AVP.is_defined('step0'), step0 = 0.5*ones(size(x0)); end
  
  Add = step0/0.05 - x0; 
  [x,fval] = fminsearch(@(x) fun(x-Add, x0 + Add), options);

  [x_m,fval_m] = fminsearch(@(x) fun(-x-Add, -x0 + Add, options);
  if fval_m < fval
    fval = fval_m; x = x_m;
  end
end
