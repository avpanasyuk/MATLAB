
function Value=opt_param(name,default,remove)
  %> check varargin on presence of a given variable
  %> @param name - string, optional variable name as specified in varargin
  %> @param default - default value
  %> @param remove - removes given variable name form varargin, so
  %> nested functions do not see it
  %> @retval Value in varargin if present, default if absent
  %> @retval out_varargin if base varargin with added default value
  Varargin = evalin('caller','varargin');
  Place = find([strcmp(Varargin(1:2:end),name)],1,'last');
    
  if isempty(Place)
    Value = default;
    assignin('caller','varargin',{Varargin{:},name,Value})
  else
    Value = Varargin{2*Place};
    if exist('remove','var') && remove 
      evalin('caller',['varargin{',num2str(2*Place-1),'} = '''';'])
    end
  end
  if nargout == 0
    assignin('caller',name,Value);
  end
end