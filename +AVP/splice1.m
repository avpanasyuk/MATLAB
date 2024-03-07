function out = splice1(n,y_end,y_start,varargin) 
  %> smoothly connect two ends of digital vectors with smooth 0th and 1st
  %> derivative. I will use "sin" as a mixing function in -pi/2 to pi/2 range and extend
  %> it with 1 and 0 constants if necessary.
  %> @param n - number of points between vectors to fill
  %> @param y_end - some number of tailing points of the first vector
  %> @param y_start - some number of starting points of the second vector
  %> @param varargin - passed to "splice"

  %  evaluate derivatives
  
  dk = AVP.deriv_kernel
  out = AVP.splice(n,y1,y2,varargin{:});
end
