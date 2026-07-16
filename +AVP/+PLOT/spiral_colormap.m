function map = spiral_colormap(N,turns,start)
%+
% START in degrees
% let's see whether we can make it using HSV space without fancy things
%-
if nargin < 2, turns = 1.5; end
if nargin < 3, start = 0; end
hsv = [mod([1:N]*turns+start,N)/N;ones([1,N]);[0:N-1]/(N-1)].';
map=AVP.CONVERT.hsv2rgb(hsv); % standard MATLAB convertion sucks badly
end

