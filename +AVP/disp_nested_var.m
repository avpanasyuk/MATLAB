function disp_nested_var(x)
  if isa(x,'char'), fprintf(['''' x '''' ]); return; end
  global disp_nested_var_level
  if isempty('disp_nested_var_level'), disp_nested_var_level = -1; end
  old_nest_level = disp_nested_var_level;
  disp_nested_var_level = disp_nested_var_level+1;
  fprintf(blanks(disp_nested_var_level));
  try
    if numel(x) > 1
      for i=1:numel(x)
        AVP.disp_nested_var([x(i)])
        fprintf(' ')
      end
      % fprintf('\n');
    else % single variable
      switch class(x)
        case 'struct'
          fields = fieldnames(x);
          for i=1:numel(fields),
            fprintf([fields{i} ':'])
            AVP.disp_nested_var(getfield(x,fields{i}));
            %          field = getfield(x,fields{i});
            %          if isa(field,'cell'), AVP.disp_nested_var({field}); ...
            %          else AVP.disp_nested_var(field); end
            fprintf('\n');
          end
        case 'cell'
          for i=1:numel(x)
            AVP.disp_nested_var(x{i})
          end
        otherwise
          disp(x)
      end
    end
  catch ME
    disp_nested_var_level = old_nest_level;
    rethrow(ME)
  end
  disp_nested_var_level = disp_nested_var_level-1;
end



