function good = check_serialport(s)
	if isempty(s), good = false; return; end
	if ~(isa(s, 'internal.Serialport') || isa(s, 'AVP.HW.WinSerial')) || ~isvalid(s)
		good = false; return;
	end
	try
		s.NumBytesAvailable;
		good = true;
	catch
    good = false;
	end
end % check_serialport