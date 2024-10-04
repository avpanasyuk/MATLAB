function [Out, Dirs] = run_in_dirs(dir_func,varargin)
  %> recursively funs DIR_FUNC in every subdirectory
  AVP.opt_param('directory','.\',1);

  Out = {};
  Dirs = {};

  [Out_, Dirs_] = dir_func(directory, varargin{:});
  Out = [Out, Out_];
  Dirs = [Dirs, Dirs_];

  entries = dir(directory);
  dirs = entries([entries.isdir]);

  for dI=3:numel(dirs) % we have subdirectories
    [Out_, Dirs_] = AVP.FILE.run_in_dirs(dir_func, ...
      'directory', [directory, dirs(dI).name filesep], varargin{:});
    Out = [Out, Out_];
    Dirs = [Dirs, Dirs_];
  end
end
