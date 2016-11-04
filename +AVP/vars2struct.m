%> assigns listed variables into fileds of the struct with the same name
%> @param varargin - cell array of variable names
function vars2struct(struct_name,varargin)
  for ni=1:numel(varargin)
    evalin('caller',[struct_name '.' varargin{ni} '=' varargin{ni} ';']);
  end
end