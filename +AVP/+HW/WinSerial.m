classdef WinSerial < matlab.mixin.SetGet
	%> Drop-in replacement for MATLAB's serialport using Win32 API via MEX.
	%> Constructor: AVP.HW.WinSerial(port, baud, Name, Value, ...)
	%>   Name-Value: 'Timeout' (s), 'DataBits', 'Parity', 'StopBits'
	%> Inherits matlab.mixin.SetGet so get(obj,'Prop')/set(obj,'Prop',v) work
	%> like serialport (e.g. get(s,'Status')). matlab.mixin.SetGet is a handle.
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
		Terminator   = "LF"       % writeline/readline line terminator: "LF","CR","CR/LF"
	end
	properties (Constant, Access=private)
		PARITY_MAP   = struct('none',0,'odd',1,'even',2,'mark',3,'space',4)
		STOPBITS_MAP = struct('one',0,'onepointfive',1,'two',2,'x1',0,'x1_5',1,'x2',2)
	end
	properties (Access=private)
		cb_timer  = []   % MATLAB timer emulating serialport's data callback
		cb_fcn    = []   % user callback, signature cb(src,event)
		cb_count  = 1    % "byte" mode: fire when this many bytes are available
	end
	methods
		function a = WinSerial(port, baud, varargin)
			p = inputParser;
			% tolerate serialport-style Name-Value pairs we don't act on
			% ('FlowControl','ByteOrder','name','Type',...) so WinSerial is a
			% true drop-in for the existing open_serialport call sites.
			p.KeepUnmatched = true;
			p.addRequired ('port',  @(x) ischar(x) || isstring(x));
			p.addRequired ('baud',  @(x) isnumeric(x) && isscalar(x));
			p.addParameter('Timeout',     10,    @(x) isnumeric(x) && isscalar(x));
			p.addParameter('WriteTimeout', 10,   @(x) isnumeric(x) && isscalar(x));
			p.addParameter('DataBits',     8,    @(x) any(x == [5 6 7 8]));
			p.addParameter('Parity',       'none', @(x) ischar(x) || isstring(x));
			p.addParameter('StopBits',     1,    @(x) any(x == [1 1.5 2]));
			p.addParameter('Terminator',   "LF", @(x) ischar(x) || isstring(x));
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
			a.Terminator   = r.Terminator;
			a.handle = AVP.HW.win32serial_mex('open', a.Port, r.baud, ...
				uint8(r.DataBits), uint8(parity_num), uint8(stop_num), ...
				uint32(round(r.Timeout * 1000)), uint32(round(r.WriteTimeout * 1000)));
			R = AVP.HW.WinSerial.registry(); R(upper(a.Port)) = a; %#ok<NASGU>
		end % WinSerial

		function delete(a)
			if ~isempty(a.cb_timer) && isvalid(a.cb_timer)
				try, stop(a.cb_timer); delete(a.cb_timer); catch, end
			end
			a.cb_timer = [];
			if a.handle ~= 0
				try, AVP.HW.win32serial_mex('close', a.handle); catch, end
				a.handle = 0;
			end
			try
				R = AVP.HW.WinSerial.registry(); key = upper(a.Port);
				if isKey(R, key) && isequal(R(key), a), remove(R, key); end
			catch, end
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

		function writeline(a, line)
			%> Write a string followed by the configured Terminator (serialport parity).
			raw = [uint8(char(line)), a.term_bytes()];
			AVP.HW.win32serial_mex('write', a.handle, raw);
		end % writeline

		function line = readline(a)
			%> Read up to (and including) the Terminator; return a string with the
			%> terminator stripped (serialport parity). Honors a.Timeout.
			term = a.term_bytes(); tlen = numel(term);
			buf = uint8([]); start = tic;
			while toc(start) < a.Timeout
				if a.NumBytesAvailable > 0
					buf = [buf, AVP.HW.win32serial_mex('try_read', a.handle, uint32(a.NumBytesAvailable))]; %#ok<AGROW>
					if numel(buf) >= tlen && isequal(buf(end-tlen+1:end), term)
						line = string(char(buf(1:end-tlen))); return
					end
				else
					pause(0.001)
				end
			end
			line = string(char(buf)); % timeout: return whatever arrived
		end % readline

		function configureTerminator(a, readTerm, ~)
			%> serialport-compatible: set the line terminator used by
			%> writeline/readline. Accepts "LF"/"CR"/"CR/LF" (or a literal). A
			%> second (write) terminator argument is accepted and ignored - this
			%> transport uses one terminator for both directions.
			a.Terminator = readTerm;
		end % configureTerminator

		function configureCallback(a, mode, varargin)
			%> serialport-compatible data callback. A MATLAB timer polls the
			%> port and fires the callback the same way serialport's event loop
			%> does (serviced during pause/drawnow). Supported:
			%>   configureCallback(s,"byte",count,@cb)  - fire when >=count bytes available
			%>   configureCallback(s,"off")             - disable
			%> The callback signature is cb(src,event), matching serialport.
			mode = lower(char(mode));
			if ~isempty(a.cb_timer) && isvalid(a.cb_timer)
				stop(a.cb_timer); delete(a.cb_timer);
			end
			a.cb_timer = []; a.cb_fcn = [];
			switch mode
				case 'off'
					return
				case 'byte'
					a.cb_count = varargin{1};
					a.cb_fcn   = varargin{2};
				case 'terminator'
					error('WinSerial:configureCallback', ...
						['"terminator" callback mode is not implemented (it needs a ' ...
						 'non-consuming buffer peek); use "byte" mode with readline.']);
				otherwise
					error('WinSerial:configureCallback', 'Unknown mode "%s"', mode);
			end
			a.cb_timer = timer('ExecutionMode','fixedSpacing', 'Period', 0.02, ...
				'BusyMode','drop', 'Name', ['WinSerial_' a.Port], ...
				'TimerFcn', @(~,~) a.cb_tick());
			start(a.cb_timer);
		end % configureCallback

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

		function b = term_bytes(a)
			%> Terminator string -> raw bytes (LF default), mirroring serialport.
			switch upper(char(a.Terminator))
				case 'LF',                b = uint8(10);
				case 'CR',                b = uint8(13);
				case {'CR/LF','CRLF'},    b = uint8([13 10]);
				otherwise,                b = uint8(char(a.Terminator));
			end
		end % term_bytes

		function cb_tick(a)
			%> Timer worker for configureCallback: fire the user callback while
			%> at least cb_count bytes are available. The callback is expected to
			%> consume bytes (as serialport callbacks do); errors are surfaced as
			%> warnings so a throwing callback doesn't silently kill the timer.
			if a.handle == 0 || isempty(a.cb_fcn), return; end
			try
				if a.NumBytesAvailable >= a.cb_count
					a.cb_fcn(a, struct('AbsTime', datetime('now')));
				end
			catch ME
				warning('WinSerial:callback', '%s', ME.message);
			end
		end % cb_tick
	end % methods

	methods (Static)
		function ports = list()
			%> Cell array of COM port names from registry.
			ports = AVP.HW.win32serial_mex('list');
		end % list

		function reg = registry()
			%> Process-wide map of live open WinSerial objects, keyed by
			%> upper-case port name. Mirrors serialportfind so open_serialport
			%> can reuse an already-open handle (Win32 opens are exclusive).
			persistent R
			if isempty(R), R = containers.Map('KeyType','char','ValueType','any'); end
			reg = R;
		end % registry

		function s = find(port)
			%> With a port name: the live, healthy WinSerial on that port, or [].
			%> With no argument: an array of all live WinSerial objects (parity
			%> with serialportfind(), which only finds internal.Serialport). Prunes
			%> dead registry entries either way.
			R = AVP.HW.WinSerial.registry();
			if nargin >= 1
				s = []; key = upper(char(port));
				if isKey(R, key)
					cand = R(key);
					if isvalid(cand) && cand.handle ~= 0
						try, cand.NumBytesAvailable; s = cand; return; catch, end
					end
					remove(R, key);
				end
				return
			end
			s = AVP.HW.WinSerial.empty;
			for k = keys(R)
				cand = R(k{1});
				if isvalid(cand) && cand.handle ~= 0
					try, cand.NumBytesAvailable; s(end+1) = cand; continue; catch, end %#ok<AGROW>
				end
				remove(R, k{1});
			end
		end % find

		function s = open(port, varargin)
			%> Find-or-create a WinSerial on @p port (reuses an already-open one
			%> from the registry; Win32 opens are exclusive). The transport-agnostic
			%> entry point is AVP.HW.open_serialport, which adds the native-backend
			%> rollback switch; call this when you specifically want a WinSerial.
			s = AVP.HW.WinSerial.find(port);
			if isempty(s), s = AVP.HW.WinSerial(port, varargin{:}); end
		end % open

		function closeall()
			%> Recovery hatch: close every open WinSerial and free every OS port
			%> handle, WITHOUT restarting MATLAB. Deletes all registered objects,
			%> then unloads the MEX so its mexAtExit closes any handle that leaked
			%> out of the registry (e.g. after 'clear classes'). Use this if a port
			%> is stuck "in use" and you have lost its object.
			try
				R = AVP.HW.WinSerial.registry();
				for k = keys(R), try, delete(R(k{1})); catch, end, end
			catch, end
			clear AVP.HW.win32serial_mex   % -> mexAtExit cleanup_all closes all handles
		end % closeall
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
