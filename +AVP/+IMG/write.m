function write(output_file,varargin)
  %>same as print only removes empty spaces. Works only for printing into
  %>image files!
  %> @param output_file - file to write. If omitted just copies figure to
  %> clipboard. The file format is determined by extension
  %> @param varargin 
  %>    - fig: figure handle
  %>    - frmt: format as recognized by imwrite, e.f. 'png'. 'jpg'
  %>    - arguments for 'imwrite' function
  %>                
  AVP.opt_param('fig',gcf,1);
  
  % find output name
  if exist('output_file','var')
    [filepath,~,ext] = fileparts(output_file);
    [~,~] = mkdir(filepath);
    if isempty(ext), ext = 'png'; else ext = strip(ext,"left",'.'); end 
    AVP.opt_param('frmt',ext,1);
    imwrite(frame2im(getframe(fig)),output_file,frmt,varargin{:});
  else
    hgexport(fig,'-clipboard')
  end
end
