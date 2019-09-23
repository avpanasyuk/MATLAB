function str = nested_var2str(x, max_chars)
  %> ~@param max_chars - cut string variables and structure field names to
  %> this number of chars. 0 mean no cutting
  if ~AVP.is_defined('max_chars'), max_chars = 0; end

  if isa(x,'char')
    if max_chars
      str = x(1:min([numel(x):max_chars]));
    else
      str = x; 
    end
    return; 
  end
  str = '';
  if numel(x) > 1
    for i=1:numel(x)
      str = [str, '_', AVP.nested_var2str([x(i)])];
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
          str = [str, '_', name, '=', AVP.nested_var2str(getfield(x,fields{i}))];
        end
        str=str(2:end);
      case 'cell'
        str = AVP.nested_var2str(x{1});
      case 'function_handle'
        str = func2str(x);
      otherwise
        str = sprintf('%g',x);
    end
  end
end



