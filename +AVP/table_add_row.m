function Tbl = table_add_row(Tbl, TblRow)
  % Not every variable in added row has to be in destination table
  NewRowVarNames = TblRow.Properties.VariableNames;
  N = size(Tbl,1);
  for vI = 1:numel(NewRowVarNames)
    % if 1 %ismember(NewRowVarNames{vI},Tbl.Properties.VariableNames)
      Tbl{N+1,NewRowVarNames{vI}} = TblRow{1,NewRowVarNames{vI}};
    % end
  end
  if ~isempty(TblRow.Properties.RowNames) && ~isempty(TblRow.Properties.RowNames{1})
    Tbl.Properties.RowNames{N+1} = TblRow.Properties.RowNames{1};
  end
end %table_add_row
