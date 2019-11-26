%> assigns listed variables into fileds of the struct with the same name
%> @param varargin - cell array of {'variable names',type_str} pairs.
function vars2struct_typed(struct_name,varargin)
  for ni=1:2:numel(varargin)
      evalin('caller',...
        [struct_name '.' varargin{ni} '=' varargin{ni+1} '(' varargin{ni} ');']);
  end
end