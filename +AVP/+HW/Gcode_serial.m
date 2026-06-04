classdef Gcode_serial < handle
	properties
		s % serial port
		Verbose = true
		Timeout double   = 30       % seconds to wait for 'ok'
	end
	methods (Access = public)
		function a = Gcode_serial(Baudrate, varargin)
			if ~AVP.opt_param_present('port',varargin)
				ports = AVP.comports();
				if numel(ports) == 1
					port = ports(1).port;
				else
					if ~AVP.opt_param_present('Name',varargin)
						error('Gcode_serial:constructor - either "Name" or "port" should be defined!');
					else
						Name = AVP.opt_param('Name',[],1);
						portI = find(strcmp(Name,{ports.name}));
						if isempty(portI), error("Failed to find port!"); end
						if numel(portI) > 1, error("There are several ports with this name!"); end
						port = ports(portI).port;
					end
				end
			else
				port = AVP.opt_param('port');
			end
			a.s = AVP.HW.open_serialport(port, Baudrate,varargin{:});
			configureTerminator(a.s, 'LF');   % \n terminator
			pause(2);
			flush(a.s);
		end % constructor

		function delete(a)
			delete(a.s)
		end

		function response = send(a, cmd)
			% SENDGCODE  Send one G-code command; block until 'ok'.
			%   response = a.send('G28');
			a.checkConnected();

			if a.Verbose
				fprintf('-> %s\n', cmd);
			end

			writeline(a.s, cmd);          % sends cmd + \n
			response = a.waitForOk();
		end

		function sendFile(a, filename)
			% SENDFILE  Stream a .gcode file line-by-line to the printer.
			fid = fopen(filename, 'r');
			if fid == -1
				error('GCodePrinter:fileNotFound', ...
					'Cannot open file: %s', filename);
			end
			lineCount = 0;
			try
				while ~feof(fid)
					line = strtrim(fgetl(fid));
					if ischar(line) && ~isempty(line)
						a.send(line);
						lineCount = lineCount + 1;
					end
				end
			catch ME
				fclose(fid);
				rethrow(ME);
			end
			fclose(fid);
			fprintf('GCodePrinter: sent %d lines from %s.\n', ...
				lineCount, filename);
		end

	end  % core communication

	% ------------------------------------------------------------------ %
	%  Convenience G-code commands
	% ------------------------------------------------------------------ %
	methods (Access = public)

		function home(a, axes)
			% HOME  Auto-home axes. axes = 'XYZ' (default), 'X', 'Y', etc.
			if nargin < 2, axes = ''; end
			a.send(['G28 ' upper(strtrim(axes))]);
		end

		function moveToXYZ(a, x, y, z, feedrate)
			%   moveTo(x, y, z)          % uses default feedrate
			%   moveTo(x, y, z, feedrate)
			if nargin < 5 || isempty(feedrate)
				cmd = sprintf('G0 X%.3f Y%.3f Z%.3f', x, y, z);
			else
				cmd = sprintf('G1 X%.3f Y%.3f Z%.3f F%d', x, y, z, feedrate);
			end
			a.send(cmd);
		end

		function waitForMoves(a)
			% WAITFORMOVES  Block until all queued moves are done (M400).
			a.send('M400');
		end

		function setHotendTemp(a, tempC, waitForTemp)
			% SETHOTENDTEMP  Set hotend temperature.
			%   waitForTemp = true  → M109 (block until reached)
			%   waitForTemp = false → M104 (set and return immediately)
			if nargin < 3, waitForTemp = false; end
			if waitForTemp
				a.send(sprintf('M109 S%d', round(tempC)));
			else
				a.send(sprintf('M104 S%d', round(tempC)));
			end
		end

		function setBedTemp(a, tempC, waitForTemp)
			% SETBEDTEMP  Set heated bed temperature.
			if nargin < 3, waitForTemp = false; end
			if waitForTemp
				a.send(sprintf('M190 S%d', round(tempC)));
			else
				a.send(sprintf('M140 S%d', round(tempC)));
			end
		end

		function [hotend, bed] = getTemperatures(a)
			% GETTEMPERATURES  Query temperatures (M105).
			%   Returns hotend and bed temperatures as doubles.
			resp = a.send('M105');
			hotend = a.parseTemp(resp, 'T:');
			bed    = a.parseTemp(resp, 'B:');
		end

		function pos = getPosition(a)
			% GETPOSITION  Query current position (M114).
			%   Returns struct with fields X, Y, Z, E.
			resp = a.send('M114');
			pos.X = a.parseCoord(resp, 'X:');
			pos.Y = a.parseCoord(resp, 'Y:');
			pos.Z = a.parseCoord(resp, 'Z:');
			pos.E = a.parseCoord(resp, 'E:');
		end

		function info = getFirmwareInfo(a)
			% GETFIRMWAREINFO  Query firmware version string (M115).
			info = a.send('M115');
		end

		function motorsOff(a)
			% MOTORSOFF  Disable all steppers (M84).
			a.send('M84');
		end

		function fanSpeed(a, speed)
			% FANSPEED  Set part cooling fan speed (0-255). 0 = off.
			a.send(sprintf('M106 S%d', min(max(round(speed),0),255)));
		end

	end  % convenience methods

	% ------------------------------------------------------------------ %
	%  Private helpers
	% ------------------------------------------------------------------ %
	methods (Access = private)

		function checkConnected(a)
			if isempty(a.s) || ~isvalid(a.s)
				error('GCodePrinter:notConnected', ...
					'Not connected. Call connect() first.');
			end
		end

		function response = waitForOk(a)
			% Read lines until one starts with 'ok', collecting all output.
			lines = {};
			deadline = tic;
			while true
				if toc(deadline) > a.Timeout
					error('GCodePrinter:timeout', ...
						'Timed out waiting for ''ok'' from printer.');
				end
				line = readline(a.s);
				if isempty(line), continue; end
				line = strtrim(string(line));
				if a.Verbose
					fprintf('<- %s\n', line);
				end
				lines{end+1} = char(line);  %#ok<AGROW>
				if startsWith(line, 'ok')
					break
				end
			end
			response = strjoin(lines, newline);
		end

		function val = parseTemp(~, str, prefix)
			% Extract numeric value after prefix like 'T:' or 'B:'.
			idx = strfind(str, prefix);
			if isempty(idx)
				val = NaN; return
			end
			rest = extractAfter(str, idx(1) + strlength(prefix) - 1);
			val  = sscanf(rest, '%f', 1);
			if isempty(val), val = NaN; end
		end

		function val = parseCoord(~, str, prefix)
			% Extract numeric coordinate after prefix like 'X:'.
			idx = strfind(str, prefix);
			if isempty(idx)
				val = NaN; return
			end
			rest = extractAfter(str, idx(1) + strlength(prefix) - 1);
			val  = sscanf(rest, '%f', 1);
			if isempty(val), val = NaN; end
		end
	end
end
