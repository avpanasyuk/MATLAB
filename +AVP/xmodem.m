function [data, packet_num] = xmodem(serial_obj_or_name,varargin)
	if strcmp(class(serial_obj_or_name), 'internal.Serialport')
		s = serial_obj_or_name;
	else
		s = serialport(serial_obj_or_name,varargin{:});
	end
	data = [];
	if s.NumBytesAvailable ~= 0, s.read(s.NumBytesAvailable,'uint8'); end
	s.write('C','uint8'); % NAK
	packet_num = 0;

	while 1
		switch s.read(1,'uint8')
			case 2 % STX
			case 4
				return; % EOT, we are done
			otherwise
				warning('Not STX or EOT');
				s.write('C','uint8'); % 5 NAK
				continue
		end

		rec_packet_num = s.read(1,'uint8');
		if s.read(1,'uint8') ~= 255 - rec_packet_num || ...
				mod(packet_num + 1,256) ~= rec_packet_num
			warning('Wrong packet number %d vs %d', rec_packet_num, packet_num);
			s.write('C','uint8'); % NAK
			continue
		end

		packet = s.read(1024,'uint8');

		CRC = swapbytes(uint16(s.read(1,'uint16')));

		if CRC ~= AVP.crc16(packet,0)
			warning('Wrong checksum %x vs %x', CRC, AVP.crc16(packet,0), 0);
			s.write('C','uint8'); % NAK
		else
			s.write(6,'uint8'); % 6 ACK
			packet_num = packet_num + 1;
			data = [data, packet];
		end
	end
end