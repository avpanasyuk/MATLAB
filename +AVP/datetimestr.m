function out = datetimestr(format)
%+
% for some weird reason MATLAB's date returns wrong date
% returns 
%-

if ~exist('format','var'), format='yyyy-mm-dd_HH-MM-SS'; end
out = datestr(clock,format);
end
