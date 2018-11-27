function call(phidget,func,varargin)
% function call(phidget,func,varargin)
% this private member calls phidget InterfaceKit functions, which start with CPhidgetInterfaceKit_
% This part should be ommited from a function name. Automatically checks result code.
% PARAMETERS:
%    FUNC - name of the phidget API function without initial CPhidgetInterfaceKit_
%    varargin - passed to function
	chk_err(phidget,calllib('plib',strcat('CPhidgetInterfaceKit_',func),phidget.handle,varargin{:}));
end

