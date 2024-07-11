% reading data
function Out = read_dir(read_file_func,varargin)
  AVP.opt_param('fn_pattern','*.json');
  AVP.opt_param('directory','.\');

  files = dir([directory fn_pattern]);
  Out = {};

  fn = {files.name};
  fn([files.isdir]) = [];

  FileI = 1;
  while 1
    try
      Out{FileI} = read_file_func(directory,fn{FileI});
    catch
      warning(['Failed to read file ' fn{FileI}]);
    end

    if FileI >= numel(fn), break; end
    FileI = FileI + 1;
  end
end
