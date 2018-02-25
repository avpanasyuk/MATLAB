classdef input_data < handle
  %>         y = Offset + Xtest*C;
  properties
    X %> AVP.LINREG.zscored
    y %> AVP.LINREG.zscored
  end
  
  methods
    function a = input_data(X,y)
      a.X = AVP.LINREG.zscored(X);
      a.y = AVP.LINREG.zscored(y);
    end
    
    function [C, Offset] = dezscore_solution(a,C_zscored)
      %> converts C_zscored which is X_zscored*C_zscored=y_zscored to
      %> X*C+Offset = y;
      %> @param C_zscored - is regression solution(s) for zscored data
      %> zscored offset = 0. It may be a matrix [x_varI,num_solutions]
      %> containing several solutions
      %> @retval C - coeff vector for original data, same size as C_zscored
      %> @retval Offset - offset vector [1,num_solutions] for original data      
      C = C_zscored./repmat(a.X.Std.',1,size(C_zscored,2))*a.y.Std;
      Offset  = a.y.Mean - a.X.Mean*C;
    end
  end
end

