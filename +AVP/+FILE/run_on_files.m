function Out = run_on_files(file_func,varargin)
  %> runs FILE_FUNC on every file in directory
  %> @param file_func: file_func(file_name, varargin{:})
  AVP.opt_param('fn_pattern','*');
  AVP.opt_param('directory','.\',1);

  Out = {};
  
  files = dir([directory fn_pattern]);
  fn = {files.name};
  fn([files.isdir]) = [];

  for fI = 1:numel(fn)
    try
      Out = [Out, file_func([directory,fn{fI}], varargin{:})];
    catch Err
      warning(['Failed to process file: ' fn{fI} ', ERROR: ', Err.message]);
    end
  end
end
