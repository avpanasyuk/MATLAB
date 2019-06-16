function [files,out] = parse_fn(scanf_format,varargin)
  %> @param scan_format - TEXTSCAN format string to parse file names with,
  %>                      SHOULD MATCH THE WHOLE FILE NAME. Items should be
  %>                      separated by underlines (by default)
  %> @param varargin - 'dir' - directory, '.' as default
  %>                   'pattern' - file pattern to match, '*' as default
  %>                   'delimiter' - string or cell array of strings, to separate strings,
  %>                                 none as default. If you specify
  %>                                 delimeter you have to specify every 
  %>                                 delimited part as a field
  %> @retval files - file names matching scan_format
  %> @retval values - array of parced with scanf_format values
  
  d = AVP.opt_param('dir','.',1);
  pattern = AVP.opt_param('pattern','*',1);
  delimiter = AVP.opt_param('Delimiter','',1);
  
  t = what();
  old_dir = t.path;
  cd(d)
  files = dir(pattern);
  files = files(3:end); % skip '.' and '..'
  files = {files.name};
  
  out = cellfun(@(str) textscan(str,scanf_format,...
      'Delimiter',delimiter,varargin{:}),files,'UniformOutput',false);
    
  out = cat(1,out{:});
  bad = cellfun(@isempty,out);
  good_ind = find(sum(bad,2) == 0);
  files = files(good_ind);
  values = out(good_ind,:);
  out = {};
  for valI=1:size(values,2)
    if ischar(values{1,valI})
      out{valI} = values(:,valI);
    else
      out{valI} = [values{:,valI}];
    end
  end
  cd(old_dir);
end

function test
  dir = [DATA_DIR 'CAP_COMP.EMPIR\'];
  pattern = '*';
end

  
  
  