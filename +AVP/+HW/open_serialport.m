function s = open_serialport(COM_name, varargin)
	%> this function checks whether the port is already open before calling
	%> "serialport"
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