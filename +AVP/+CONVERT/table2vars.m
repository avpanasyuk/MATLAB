%> copies table columns to variables
function table2vars(tbl)
  clmn_names =  tbl.Properties.VariableNames;
  for ni=1:numel(clmn_names)
    assignin('caller',clmn_names{ni},tbl{:,ni});    
  end
end
