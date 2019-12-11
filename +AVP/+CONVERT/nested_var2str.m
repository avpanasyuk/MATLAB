function str = nested_var2str(x, varargin)
  %> ~@param max_chars - cut string variables and structure field names to
  %> this number of chars. 0 mean no cutting
  AVP.opt_param('max_chars',0);
  AVP.opt_param('do_hash',0);
  AVP.opt_param('divider',' ');
  
  
  if isempty(x)
    str = '';
  else if isa(x,'char')
      if(do_hash), x = rptgen.hash(x); end
      if max_chars
        str = x(1:min([numel(x),max_chars]));
      else
        str = x;
      end
      return;
    end
    str = '';
    if numel(x) > 1
      for i=1:numel(x)
        str = [str, divider, AVP.CONVERT.nested_var2str([x(i)],varargin{:})];
      end
      str = str(2:end);
    else % single variable
      switch class(x)
        case 'struct'
          fields = fieldnames(x);
          for i=1:numel(fields)
            if max_chars
              name = fields{i}(1:min([numel(fields{i}),max_chars]));
            else
              name = fields{i};
            end
            str = [str, divider, name, ':', ...
              AVP.CONVERT.nested_var2str(getfield(x,fields{i}),varargin{:})];
          end
          str=str(2:end);
        case 'cell'
          str = AVP.CONVERT.nested_var2str(x{1},varargin{:});
        case 'function_handle'
          str =  AVP.CONVERT.nested_var2str(func2str(x),varargin{:});
        otherwise
          str = sprintf('%g',x);
      end
    end
  end
end



