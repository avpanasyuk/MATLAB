function y = unwrap(y,x,varargin)
  %> for smooth data vector with few jumps removes jumps. 
  AVP.opt_param('OverCoeff',10); % how big jump is in comparizon with median step
  if ~AVP.is_defined('x'), x = [1:numel(y)].'; end
  y = double(y(:));
  dY = AVP.diff(y)./AVP.diff(x);
  dYmed = median(dY);
  jumpIs = [1;find(abs(dY) > abs(dYmed)*OverCoeff);numel(y)];
  for jI = 2:numel(jumpIs)-1
    Nprev = jumpIs(jI) - jumpIs(jI-1);
    Npost = jumpIs(jI+1) - jumpIs(jI);
    if Npost > Nprev
      if Npost > 6
        p = polyfit(x(jumpIs(jI)+1:jumpIs(jI+1)),y(jumpIs(jI)+1:jumpIs(jI+1)),2);
      else if Npost >= 2
          p = polyfit(x(jumpIs(jI)+1:jumpIs(jI+1)),y(jumpIs(jI)+1:jumpIs(jI+1)),1);
        else error('Too many jumps!');
        end
      end
      Correction = polyval(p,x(jumpIs(jI))) - y(jumpIs(jI));
      y(1:jumpIs(jI)) = y(1:jumpIs(jI)) + Correction;
    else
      if Nprev > 6
        p = polyfit(x(jumpIs(jI-1)+1:jumpIs(jI)),y(jumpIs(jI-1)+1:jumpIs(jI)),2);
      else if Nprev >= 2
          p = polyfit(x(jumpIs(jI-1)+1:jumpIs(jI)),y(jumpIs(jI-1)+1:jumpIs(jI)),1);
        else error('Too many jumps!');
        end
      end
    end
    Correction = polyval(p,x(jumpIs(jI)+1)) - y(jumpIs(jI)+1);
    y(jumpIs(jI)+1:end) = y(jumpIs(jI)+1:end) + Correction;
  end
end

