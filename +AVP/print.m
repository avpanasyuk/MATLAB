function IMG.write_png(varargin,output_file)
%+ same as print only removes empty spaces. Works only for printing into
%image files!
%-
% we are going to make a draft print first, remove empty rows and columns
% and then make real print.

% find output name
temp_file = 't382382149382.png'
print([{varargin},{'-dpng',tempfile}]);
Im = imread(temp_file);

% fix empty spaces
end


