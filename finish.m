if exist('PROJECT_DIR','var')
  h = matlab.desktop.editor.getAll;
  f = fopen([PROJECT_DIR '\matlab.files'],'wt');
  fprintf(f,'%s\n',h(~strcmp({h.Filename},'Untitled')).Filename);
  fclose(f);
end
