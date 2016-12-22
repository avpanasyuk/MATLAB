function [files,varargout] = parse_fn1(scanf_format,varargin)
  %> @param scan_format - scanf format string to parse file names with,
  %>                      SHOULD MATCH THE WHOLE FILE NAME
  %> @param varargin - 'dir' - directory, '.' as default
  %>                   'pattern' - file pattern to match, '*' as default
  %> @retval files - file names matching scan_format
  %> @retval varargout - output parameters  corrrespond to scanf_format values
  
  [files,values] = AVP.parse_fn(scanf_format,varargin{:});
  for outi=1:nargout-1
    varargout{outi} = values(outi,:);
  end
end

  
  
  