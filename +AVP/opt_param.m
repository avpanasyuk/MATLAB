
function Value=opt_param(name,default,action)
  %> check varargin on presence of a given variable
  %> @param name - string, optional variable name as specified in varargin
  %> @param default - default value
  %> @param action: logical bitmap
  %>     - if bit 1 is true removes given variable name form varargin
  %>     - if bit 2 is true adds default value to varargin if absent (default)
  %> @retval Value in varargin if present, default if absent
  %> @retval out_varargin if base varargin with added default value
  
  Varargin = evalin('caller','varargin');
  Place = AVP.opt_param_present(name,Varargin);
  if ~AVP.is_defined('action'), action = 2; end
  if ~AVP.is_defined('default'), default = []; end
    
  if isempty(Place)
    Value = default;
    if AVP.getbit(action,2), assignin('caller','varargin',{Varargin{:},name,Value}); end
  else
    Value = Varargin{2*Place};
    if AVP.getbit(action,1) 
      evalin('caller',['varargin(',num2str(2*Place-1),':',num2str(2*Place),') = [];'])
    end
  end
  if nargout == 0
    assignin('caller',name,Value);
  end
end
