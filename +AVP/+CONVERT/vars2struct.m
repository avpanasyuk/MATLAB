%> assigns listed variables into fields of the struct with the same name
%> @param varargin - cell array of variable names
function out = vars2struct(varargin)
  if nargout % we return created struct
    if numel(varargin) == 0 % if we have not specified variables do all of them
      varargin = evalin('caller','who()');
    end
    for ni=1:numel(varargin)
      out.(varargin{ni}) = evalin('caller',varargin{ni});
    end
  else % we assign the created struct to the first name in varargin
    struct_name = varargin{1};
    varargin = varargin(2:end);
    
    if numel(varargin) == 0 % if we have not specified variables do all of them
      varargin = evalin('caller','who()');
    end
    for ni=1:numel(varargin)
      if ~strcmp(varargin{ni},struct_name) % no circular inclusion
        evalin('caller',[struct_name '.' varargin{ni} '=' varargin{ni} ';']);
      end
    end
  end
end
