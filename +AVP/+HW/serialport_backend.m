function out = serialport_backend(set_to)
	%> Get/set the serial transport backend used by AVP.HW.open_serialport.
	%>   'winserial' (default) - AVP.HW.WinSerial (Win32 API via MEX)
	%>   'native'              - MATLAB's built-in serialport
	%> Persistent for the MATLAB session. This is the rollback switch: if
	%> WinSerial ever misbehaves, AVP.HW.serialport_backend('native') reverts
	%> every open_serialport call site to the built-in serialport with no code
	%> change or restart. Call with no args to read the current backend.
	persistent backend
	if isempty(backend), backend = 'winserial'; end
	if nargin >= 1 && ~isempty(set_to)
		set_to = lower(char(set_to));
		if ~ismember(set_to, {'winserial','native'})
			error('serialport_backend:bad', 'backend must be ''winserial'' or ''native''');
		end
		backend = set_to;
	end
	out = backend;
end % serialport_backend
