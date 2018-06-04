if exist('MATLAB_DIR','var')
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
%   % strip REP_ROOT
%   if exist('REP_ROOT','var')
%     Filenames = strrep(Filenames,[REP_ROOT '\'],'');
%   end
  f = fopen([MATLAB_DIR '\matlab.files'],'wt');
  fprintf(f,'%s\n',Filenames{cellfun(@isempty,regexp(Filenames,'.*\Untitled[2-9]*'))});
  fclose(f);
end
