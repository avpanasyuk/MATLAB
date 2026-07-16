function cell_of_str = num2str(x,varargin)
  % differ from MATLAB's in that it converts to a cell array of strings
  % which can be used, e.g. in LEGEND
  cell_of_str = cellfun(@(x) num2str(x,varargin{:}),num2cell(x),'UniformOutput',false);
end