if exist('AVP.is_defined') && AVP.is_defined('INIT_DIR')
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
  f = fopen([INIT_DIR '\matlab.files'],'wt');
  fprintf(f,'%s\n',Filenames{cellfun(@isempty,regexp(Filenames,'.*\Untitled[2-9]*'))});
  fclose(f);
end
