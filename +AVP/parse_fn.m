function [files,values] = parse_fn(scanf_format,varargin)
  %> @param scan_format - TEXTSCAN format string to parse file names with,
  %>                      SHOULD MATCH THE WHOLE FILE NAME. Items should be
  %>                      separated by underlines (by default)
  %> @param varargin - 'dir' - directory, '.' as default
  %>                   'pattern' - file pattern to match, '*' as default
  %> @retval files - file names matching scan_format
  %> @retval values - array of parced with scanf_format values
  
  d = AVP.opt_param('dir','.',1);
  pattern = AVP.opt_param('pattern','*',1);
  delimiter = AVP.opt_param('Delimiter','_',1);
  
  t = what();
  old_dir = t.path;
  cd(d)
  files = dir(pattern);
  files = files(3:end); % skip '.' and '..'
  files = {files.name};
  
  out = cellfun(@(str) textscan(str,scanf_format,...
      'Delimiter',delimiter,varargin{:}),files,'UniformOutput',false);
    
  out1 = reshape([out{:}],[],size(out,2));
  for valI=size(out1,2):-1:1
    values{valI} = [out1{valI,:}];
  end
  cd(old_dir);
end

function test
  dir = [DATA_DIR 'CAP_COMP.EMPIR\'];
  pattern = '*';
end

  
  
  