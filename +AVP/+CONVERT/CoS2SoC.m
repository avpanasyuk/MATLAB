function out = CoS2SoC(x, names)
  %> converts columns of structures into structures of
  %> columns. All structures in the column should have the same
  %> fields, and each field the same number of rows
  for cI = 1:size(x,2)
    if iscell(x)
      x_ = cat(1,x{:,cI});
    else
      x_ = x(:,cI);
    end
    
    if ~AVP.is_defined('names')
      names_ = fieldnames(x_(1));
    else names_ = names;
    end
    
    for fi=1:numel(names_)
      % let's see whether number of rows of this field for every structure is the
      % same, so we can do conversion
      ncols = cellfun(@(x) size(x,2),{x_.(names_{fi})},'UniformOutput',false);
      if ~isequal(ncols{:})
        error('Number of colums should be equal for every element!');
      end
      out(1,cI).(names_{fi}) = cat(1,x_.(names_{fi}));
    end
  end
end


