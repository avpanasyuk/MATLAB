function s = open_serialport(COM_name, varargin)
	%> this function checks whether the port is already open before calling
	%> "serialport"
	%> @note Verified driving the SENZIME PST simulator over USB-CDC (STM32F303
	%>   virtual COM port) across many connect/reconnect cycles, 2026-06.
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
end % COM_name