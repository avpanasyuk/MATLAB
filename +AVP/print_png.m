function print_png(output_file,varargin)
%+ same as print only removes empty spaces. Works only for printing into
%image files!
%-
% we are going to make a draft print first, remove empty rows and columns
% and then make real print.

% find output name
temp_file = 't382382149382.png';
print(varargin{:},'-dpng',temp_file);
Im = 255 - imread(temp_file); % negative, white is 0
% fix empty spaces
BG = ~any(Im,3);
Im(all(BG,2),:,:) = [];
Im(:,find(all(BG,1)),:) = [];
imwrite(255-Im,output_file,'png');
delete(temp_file);
end


