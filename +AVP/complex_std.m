function [AbsStd, AngleStd, NormAbsStd, NormAngleStd, AbsMean, AngleMean] = complex_std(x,varargin)
  %> @retval NormAbsStd - if defined is calculated
  %> @retval NormAngleStd - if defined is calculated
  
  AVP.opt_param('dim',1);
  abs_x = abs(x);
  angle_x = angle(x);
  
  [AbsStd, AbsMean] = AVP.std(abs_x,varargin{:});
  [AngleStd, AngleMean] = AVP.std(angle_x,varargin{:});
  
  if nargout > 2
    NormAbsStd = AbsStd./AbsMean;
      if nargout > 3
        NormAngleStd = AngleStd./abs(AngleMean);
      end
  end
end