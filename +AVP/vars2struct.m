%> assigns listed variables into fileds of the struct with the same name
%> @param varargin - cell array of variable names
function vars2struct(struct_name,varargin)
  for ni=1:numel(varargin)
    if ~strcmp(varargin{ni},struct_name) % do not need self assignment
      evalin('caller',[struct_name '.' varargin{ni} '=' varargin{ni} ';']);
    end
  end
end