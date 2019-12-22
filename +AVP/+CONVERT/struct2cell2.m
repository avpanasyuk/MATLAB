function cell_array = struct2cell2(s,varargin)
  %> converts fields into {'field_name',field_value,...} array
  AVP.opt_param('exclude',{});
  fn = setdiff(fieldnames(s),exclude);
  cell_array = {};
  for fI = 1:numel(fn)
    cell_array = {cell_array{:}, fn{fI}, s.(fn{fI})};
  end
end
