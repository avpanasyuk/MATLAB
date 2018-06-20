if ~AVP.is_defined('MFILES_DIR') && AVP.is_defined('MATLAB_DIR')
  MFILES_DIR = MATLAB_DIR;
end

if AVP.is_defined('MFILES_DIR')
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
%   % strip REP_ROOT
%   if exist('REP_ROOT','var')
%     Filenames = strrep(Filenames,[REP_ROOT '\'],'');
%   end
  f = fopen([MFILES_DIR '\matlab.files'],'wt');
  fprintf(f,'%s\n',Filenames{cellfun(@isempty,regexp(Filenames,'.*\Untitled[2-9]*'))});
  fclose(f);
end
