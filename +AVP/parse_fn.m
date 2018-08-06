function [files,values] = parse_fn(scanf_format,varargin)
  %> @param scan_format - scanf format string to parse file names with,
  %>                      SHOULD MATCH THE WHOLE FILE NAME
  %> @param varargin - 'dir' - directory, '.' as default
  %>                   'pattern' - file pattern to match, '*' as default
  %> @retval files - file names matching scan_format
  %> @retval values - array of parced with scanf_format values
  
  d = AVP.opt_param('dir','.');
  pattern = AVP.opt_param('pattern','*');
  
  t = what();
  old_dir = t.path;
  cd(d)
  files = dir(pattern);
  files = files(3:end); % skip '.' and '..'
  files = {files.name};
  
  function out  = scanf(str)
    [out.values, out.count, out.errmsg] = sscanf(str,scanf_format);
  end
  
  out = cellfun(@(str) scanf(str),files); %,'UniformOutput',false);
  good_ids = find(strcmp({out.errmsg},''));
  out = out(good_ids);
  files = files(good_ids).';
  values = [out.values].'; 
  
  cd(old_dir);
end

function test
  dir = [DATA_DIR 'CAP_COMP.EMPIR\'];
  pattern = '*';
end

  
  
  