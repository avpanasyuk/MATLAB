function write_png(output_file,varargin)
  %!same as print only removes empty spaces. Works only for printing into
  %!image files!
  %! @param output_file - file to write. If omitted just copies figure to
  %! clipboard
  %! @param varargin - arguments for 'print' function, like '-r200'
  % we are going to make a draft print first, remove empty rows and columns
  % and then make real print.
  
  % find output name
  if exist('output_file','var')
    temp_file = [tempname '.png'];
    print(varargin{:},'-dpng',temp_file);
    Im = 255 - imread(temp_file); % negative, white is 0
    % fix empty spaces
    BG = ~any(Im,3);
    Im(all(BG,2),:,:) = [];
    Im(:,find(all(BG,1)),:) = [];
    [~,~] = mkdir(fileparts(output_file));
    imwrite(255-Im,output_file,'png');
    delete(temp_file);
  else
    hgexport(gcf,'-clipboard')
  end
end
