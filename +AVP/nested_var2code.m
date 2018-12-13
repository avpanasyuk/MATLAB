function out_str = nested_var2code(var_name)
  % no tables, individual, array, cell array, string and struct
  endl = char(13);
  x = evalin('caller',var_name);
  if numel(x) > 1
    out_str = '';
    for i=1:numel(x)
      if iscell(x), index = '{' + num2str(i) + '}';
      else index = '(' + num2str(i) + ')';
      end
      out_str = out_str + AVP.nested_var2code(var_name + index);
    end
    out_str = var_name + ' = reshape(' + var_name + ',' + mat2str(size(x)) + ');' + endl; % restore proper dimensions
  else % single variable
    switch class(x)
      case 'char'
        out_str = var_name + ' = ''' + x + ''';' + endl;
      case 'struct'
        fields = fieldnames(x);
        out_str = '';
        for i=1:numel(fields),
          out_str = out_str + AVP.disp_nested_var(var_name + '.' + fields{i});
        end
      case 'cell'
        out_str = AVP.disp_nested_var(var_name + '{1}');
      otherwise
        out_str =  var_name + ' = ' + class(x) + '(' + num2str(x) + ');' + endl;
    end
  end
  
  
  
  
  
  
  
  
