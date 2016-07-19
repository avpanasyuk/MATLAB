classdef input_data < handle
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
      %> @param C_zscored - is regression solution for zscored data
      %> zscored offset = 0
      %> @retval C - coeff vector for original data [x_varI,1]
      %> @retval Offset - offset vector for original data
      
      C = C_zscored./a.X.Std.'*a.y.Std;
      Offset  = a.y.Mean - a.X.Mean*C;
    end
  end
end

