function call_common(phidget,func,varargin)
% function call_common(phidget,func,varargin)
% this private member calls phidget common functions, which start with CPhidget_
% This part should be ommited from a function name. Automatically checks result code.
% PARAMETERS:
%    FUNC - name of the phidget API function without initial CPhidget_
%    varargin - passed to function
	chk_err(phidget,calllib('plib',strcat('CPhidget_',func),phidget.handle,varargin{:}));
end

