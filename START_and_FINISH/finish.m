try
  has_init_dir = AVP.is_defined('INIT_DIR');
catch ME
  has_init_dir = false;
end
if has_init_dir
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
  f = fopen([INIT_DIR filesep 'matlab.files'],'wt');
  fprintf(f,'%s\n',Filenames{cellfun(@isempty,regexp(Filenames,'.*\Untitled[2-9]*'))});
  fclose(f);
end
