function [Out, Dirs] = read_dir(read_file_func,varargin)
%> recursively reads files in directory and its subdirectories
  AVP.opt_param('fn_pattern','*.json');
  AVP.opt_param('directory','.\',1);

  Out = {};
  Dirs = {};

  entries = dir(directory);
  dirs = entries([entries.isdir]);

  for dI=3:numel(dirs) % we have subdirectories
    [Out_, Dirs_] = AVP.FILE.read_dir(read_file_func, ...
      'directory', [directory, dirs(dI).name filesep], varargin{:});
    Out = [Out, Out_];
    Dirs = [Dirs, Dirs_];
  end

  files = dir([directory fn_pattern]);
  fn = {files.name};
  fn([files.isdir]) = [];

  for fI = 1:numel(fn)
    try
      Out = [Out, read_file_func(directory,fn{fI})];
      Dirs = [Dirs, directory];
    catch Err
      warning(['Failed to read file: ' Err.message]);
    end
  end


end
