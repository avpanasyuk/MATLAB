function s = open_serialport(COM_name, varargin)
	%> Open (or reuse) a serial port. The backend is selected by
	%> AVP.HW.serialport_backend (default 'winserial'); call
	%> AVP.HW.serialport_backend('native') to fall back to MATLAB's built-in
	%> serialport if WinSerial misbehaves. Both paths reuse an already-open
	%> handle for the same port (Win32 opens are exclusive).
	%> @note Verified driving the SENZIME PST simulator over USB-CDC (STM32F303
	%>   virtual COM port) across many connect/reconnect cycles, 2026-06.
	if strcmp(AVP.HW.serialport_backend(), 'native')
		% --- built-in serialport, reuse via serialportfind ---
		s = serialportfind();
		if ~isempty(s)
			port_match = strcmpi([s.Port], COM_name);
			if any(port_match)
				s = s(find(port_match,1));
				try
					s.NumBytesAvailable;
					return
				catch
				end
			end
		end
		s = serialport(COM_name, varargin{:});
		return
	end
	% --- default: AVP.HW.WinSerial (Win32 API via MEX), reuse via its registry ---
	s = AVP.HW.WinSerial.find(COM_name);
	if ~isempty(s), return; end
	s = AVP.HW.WinSerial(COM_name, varargin{:});
end % open_serialport