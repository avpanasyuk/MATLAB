function good = check_serialport(s)
	if isempty(s), good = false; return; end
	if ~strcmp(class(s), 'internal.Serialport') || ~isvalid(s), good = false; return; end
	try
		s.NumBytesAvailable;
		good = true;
	catch
    good = false;
	end
end % check_serialport