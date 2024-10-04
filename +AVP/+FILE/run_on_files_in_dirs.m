function [Out, Dirs] = run_on_files_in_dirs(file_func,varargin)
  %> recursively run FILE_FUNC on every file fitting pattern in subdirectories
  %> @param file_func: file_func(file_name, varargin)
  %> @param varargin:
  %>        - fn_pattern: file name pattern
  %>        - directory: directory to run in

  AVP.opt_param('fn_pattern','*');
  AVP.opt_param('directory','.\',1);

  [Out, Dirs] = AVP.FILE.run_in_dirs(...
    @AVP.FILE.run_on_files(file_func, varargin{:}), ...
      'directory', [directory, dirs(dI).name filesep], varargin{:});
end
