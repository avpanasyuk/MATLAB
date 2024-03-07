function out = splice(n,y1,y2,varargin)
  %> smoothly connect two ends of digital vectors with smooth 0th and 1st
  %> derivative. I will use "sin" as a mixing function in -pi/2 to pi/2 range and extend
  %> it with 1 and 0 constants if necessary.
  %> @param n - number of points between vectors to fill
  %> @param y1 - vector of 2, [y, dy/dx] at the end of the first vector
  %> @param y2 - vector of 2, [y, dy/dx] at the beginning of the second vector
  %> @param varargin
  %>      - t: transition distance, default is n, the transition weight function 
  %>        is array of 0s, sin from 0 to 1 over t points, arrays of 1
  %>         n points all together  
  
  AVP.opt_param('t',n);

  if t ~= n, cn = fix((n - t)/2); t = n - 2*cn; else cn = 0; end
  
  % build transition function
  tf = (sin((2*[1:t]-(t+1))/(t-1)*pi/2) + 1)/2; % from 0 to 1
  if cn ~= 0, tf = [zeros(1,cn), tf, ones(1,cn)]; end
  
  % extrapolate the vectors over n
  extr1 = [1:n]*y1(2)+y1(1);
  extr2 = y2(1) - [n:-1:1]*y2(2);
  out = extr1.*(1-tf) + extr2.*tf;
end