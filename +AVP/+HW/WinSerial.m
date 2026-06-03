classdef WinSerial < handle
	%> Drop-in replacement for MATLAB's serialport using Win32 API via MEX.
	%> Constructor: AVP.HW.WinSerial(port, baud, Name, Value, ...)
	%>   Name-Value: 'Timeout' (s), 'DataBits', 'Parity', 'StopBits'
	properties (SetAccess=protected, GetAccess=public)
		Port      = ''
		handle    = 0
	end
	properties (Dependent)
		NumBytesAvailable
		Status
	end
	properties (Access=public)
		BaudRate     = 115200
		Timeout      = 10         % seconds (to match serialport semantics)
		WriteTimeout = 10         % seconds
	end
	properties (Constant, Access=private)
		PARITY_MAP   = struct('none',0,'odd',1,'even',2,'mark',3,'space',4)
		STOPBITS_MAP = struct('one',0,'onepointfive',1,'two',2,'x1',0,'x1_5',1,'x2',2)
	end
	methods
		function a = WinSerial(port, baud, varargin)
			p = inputParser;
			p.addRequired ('port',  @(x) ischar(x) || isstring(x));
			p.addRequired ('baud',  @(x) isnumeric(x) && isscalar(x));
			p.addParameter('Timeout',     10,    @(x) isnumeric(x) && isscalar(x));
			p.addParameter('WriteTimeout', 10,   @(x) isnumeric(x) && isscalar(x));
			p.addParameter('DataBits',     8,    @(x) any(x == [5 6 7 8]));
			p.addParameter('Parity',       'none', @(x) ischar(x) || isstring(x));
			p.addParameter('StopBits',     1,    @(x) any(x == [1 1.5 2]));
			p.parse(port, baud, varargin{:});
			r = p.Results;

			parity_num = a.PARITY_MAP.(lower(char(r.Parity)));
			if r.StopBits == 1,        stop_num = 0;
			elseif r.StopBits == 1.5,  stop_num = 1;
			else,                      stop_num = 2;
			end

			a.Port     = char(r.port);
			a.BaudRate = r.baud;
			a.Timeout      = r.Timeout;
			a.WriteTimeout = r.WriteTimeout;
			a.handle = AVP.HW.win32serial_mex('open', a.Port, r.baud, ...
				uint8(r.DataBits), uint8(parity_num), uint8(stop_num), ...
				uint32(round(r.Timeout * 1000)), uint32(round(r.WriteTimeout * 1000)));
		end % WinSerial

		function delete(a)
			if a.handle ~= 0
				try, AVP.HW.win32serial_mex('close', a.handle); catch, end
				a.handle = 0;
			end
		end % delete

		function out = get.NumBytesAvailable(a)
			if a.handle == 0, out = 0; return; end
			out = AVP.HW.win32serial_mex('available', a.handle);
		end % NumBytesAvailable

		function out = get.Status(a)
			if a.handle == 0
				out = 'closed';
			elseif AVP.HW.win32serial_mex('isopen', a.handle)
				out = 'open';
			else
				out = 'closed';
			end
		end % Status

		function set.Timeout(a, v)
			a.Timeout = v;
			if a.handle ~= 0 %#ok<MCSUP>
				AVP.HW.win32serial_mex('set_timeout', a.handle, ...
					uint32(round(v*1000)), uint32(round(a.WriteTimeout*1000))); %#ok<MCSUP>
			end
		end % set.Timeout

		function set.WriteTimeout(a, v)
			a.WriteTimeout = v;
			if a.handle ~= 0 %#ok<MCSUP>
				AVP.HW.win32serial_mex('set_timeout', a.handle, ...
					uint32(round(a.Timeout*1000)), uint32(round(v*1000))); %#ok<MCSUP>
			end
		end % set.WriteTimeout

		function set.BaudRate(a, v)
			a.BaudRate = v;
			if a.handle ~= 0 %#ok<MCSUP>
				AVP.HW.win32serial_mex('set_baud', a.handle, uint32(v));
			end
		end % set.BaudRate

		function out = read(a, n, type)
			if nargin < 3, type = 'uint8'; end
			type = char(type);
			bytes_per = AVP.HW.WinSerial.bytes_for_type(type);
			raw = AVP.HW.win32serial_mex('read', a.handle, ...
				uint32(n * bytes_per), uint32(round(a.Timeout * 1000)));
			if strcmp(type, 'uint8')
				out = raw;
			elseif strcmp(type, 'int8')
				out = typecast(raw, 'int8');
			else
				out = typecast(raw, type);
			end
			out = out(:).';
		end % read

		function write(a, data, type)
			if nargin < 3, type = 'uint8'; end
			type = char(type);
			if ischar(data) || isstring(data)
				raw = uint8(char(data));
			else
				raw = typecast(cast(data(:), type), 'uint8');
			end
			AVP.HW.win32serial_mex('write', a.handle, raw);
		end % write

		function flush(a, which)
			if a.handle == 0, return; end
			if nargin < 2
				AVP.HW.win32serial_mex('flush', a.handle);
			else
				AVP.HW.win32serial_mex('flush', a.handle, char(which));
			end
		end % flush

		function out = try_read(a, n)
			%> Non-blocking; returns up to n bytes that are currently available.
			out = AVP.HW.win32serial_mex('try_read', a.handle, uint32(n));
		end % try_read

		function info = info(a)
			info = AVP.HW.win32serial_mex('info', a.handle);
		end % info

		function disp(a)
			if a.handle == 0
				fprintf('  AVP.HW.WinSerial (closed)\n\n');
				return;
			end
			fprintf('  AVP.HW.WinSerial on %s, %d baud, Timeout=%g s, %d bytes available\n\n', ...
				a.Port, a.BaudRate, a.Timeout, a.NumBytesAvailable);
		end % disp
	end % methods

	methods (Static)
		function ports = list()
			%> Cell array of COM port names from registry.
			ports = AVP.HW.win32serial_mex('list');
		end % list
	end

	methods (Static, Access=private)
		function n = bytes_for_type(t)
			switch lower(t)
				case {'uint8','int8','char','logical'},  n = 1;
				case {'uint16','int16'},                  n = 2;
				case {'uint32','int32','single'},         n = 4;
				case {'uint64','int64','double'},         n = 8;
				otherwise, error('WinSerial:bytes_for_type','Unsupported type %s',t);
			end
		end % bytes_for_type
	end
end % WinSerial
