if exist('PROJECT_DIR','var')
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
  % strip REP_ROOT
  if exist('REP_ROOT','var')
    Filenames = strrep(Filenames,[REP_ROOT '\'],'');
  end
  f = fopen([PROJECT_DIR '\matlab.files'],'wt');
  fprintf(f,'%s\n',Filenames{~strcmp(Filenames,'Untitled')});
  fclose(f);
end
