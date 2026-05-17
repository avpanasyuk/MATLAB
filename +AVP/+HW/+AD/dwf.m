classdef dwf < handle
	%> Direct MATLAB wrapper around Digilent WaveForms SDK (dwf.dll) for the
	%> Analog Discovery 1 (original). Uses loadlibrary/calllib - no DAQ Toolbox.
	%>
	%> Method names map 1:1 to FDwf* functions: a member named XYZ calls
	%>   calllib('dwf', 'FDwfXYZ', a.h, ...)
	%> via the @c Call() / @c GetValue() dispatch helpers, which read the calling
	%> method's own name from @c dbstack. Adding a new wrapper is one line:
	%>   function AnalogInReset(a), a.Call(); end
	%>
	%> Per-channel state (scope, wavegen, supplies) lives on dedicated channel
	%> classes (@c AnalogInChannel, @c AnalogOutChannel, @c AnalogIOChannel),
	%> eagerly instantiated in the constructor and reached as
	%> @c a.In(k) / @c a.Out(k) / @c a.IO(k) (1-based MATLAB indexing).
	%>
	%> Covers what the AD1 actually has: 2 scope channels, 2 wavegen channels,
	%> the ±5 V supplies (Analog I/O), trigger plumbing. Skips DMM, FIR/IIR,
	%> Power Out, Eclypse/ADP-only constants and digital protocols.
	%
	% Typical record-mode workflow (continuous streaming, NaN-padded for losses):
	%   ad = AVP.HW.AD.dwf();                              % opens first AD1
	%   ad.AnalogInReset();
	%   ad.In(1).RangeSet(5);                              % ±2.5 V (per channel)
	%   ad.In(2).RangeSet(5);
	%   ad.AnalogInFrequencySet(40e3);                     % sample rate, Hz
	%
	% Two steps matter for record mode:
	%   ARM   = device leaves DwfStateReady, ready to capture (or sit waiting for trigger)
	%   FIRE  = trigger condition met, samples start flowing into the FIFO
	% With trigsrcNone (default) ARM and FIRE happen in the same call (InitRecording).
	% With any other trigger source InitRecording only ARMs; FIRE happens later.
	%
	% InitRecording takes the recording length (seconds AFTER the trigger fires;
	% Inf or -1 = unbounded) as its last argument, so each call site is self-contained.
	%
	%   % --- Free-run (no trigger): InitRecording does ARM + FIRE -----------
	%   rec       = ad.InitRecording([1 2], 'None', 2);      % 2 s capture
	%   [y, lost] = ad.DoRecording(rec);                     % nSamples derived from length × fs
	%
	%   % --- Software-triggered: ARM now, FIRE later ------------------------
	%   rec = ad.InitRecording([1 2], 'PC', 2);              % ARM (DwfStateArmed, FIFO empty)
	%   % ... do whatever needs to happen first, then:
	%   ad.DeviceTriggerPC();                                % FIRE
	%   [y, lost] = ad.DoRecording(rec);                     % collects 2 s after FIRE
	%
	%   % --- External BNC trigger ------------------------------------------
	%   rec = ad.InitRecording([1 2], 'External1', 2);       % ARM, wait for BNC T1 edge
	%   [y, lost] = ad.DoRecording(rec);                     % FIRE happens externally
	%
	%   % --- Background (timer-driven drain - works with any trigger source)
	%   rec = ad.InitRecording([1 2], 'PC', 5);              % 5 s after trigger
	%   ad.StartBackgroundRecording(rec);                    % timer drains FIFO once samples arrive
	%   % ... prep work, then:
	%   ad.DeviceTriggerPC();                                % FIRE (omit for 'None')
	%   % ... do other MATLAB work while samples accumulate ...
	%   while ~ad.IsBackgroundRecordingDone(), pause(0.05); end
	%   [y, lost] = ad.StopBackgroundRecording();
	%
	% Notes:
	%   - InitRecording enforces acqmodeRecord, enables only the listed channels,
	%     sets BufferSize to max, and arms the acquisition.
	%   - DoRecording fills @c y with @c NaN where the SDK reported lost samples,
	%     so @c (0:N-1)/fs stays a truthful time axis.
	%   - Sample values are in VOLTS (double), already scaled by the device for
	%     the active @c RangeSet / @c OffsetSet / @c AttenuationSet and per-channel
	%     calibration. Multiply by 1000 for mV. The raw-codes path
	%     (@c In(k).StatusData16) is the only exception - those are unscaled int16.

	properties
		h    %>< HDWF device handle returned by @c FDwfDeviceOpen
		In   %>< AVP.HW.AD.AnalogInChannel array (1-based; SDK idx is 0-based internally)
		Out  %>< AVP.HW.AD.AnalogOutChannel array
		IO   %>< AVP.HW.AD.AnalogIOChannel array
	end

	properties (Transient, Hidden)
		bg = []  %>< background-recording state struct, populated by StartBackgroundRecording
	end

	properties (Constant, Hidden)
		%% ---- ENUMs from the current dwf.h (2022+) - kept to what AD1 uses

		% Enumeration filters - bitmap (new in current SDK; was a type enum before)
		enumfilterAll     = 0
		enumfilterType    = 0x8000000  % OR with a devid* to filter by device type
		enumfilterUSB     = 0x0000001
		enumfilterDemo    = 0x4000000

		% Device IDs (only AD1 is relevant here)
		devidDiscovery    = 2

		% Device versions
		devverDiscoveryA  = 1
		devverDiscoveryB  = 2
		devverDiscoveryC  = 3

		% Trigger sources (AD1 doesn't have External3/4 or DIO)
		trigsrcNone              = 0
		trigsrcPC                = 1   % software trigger via @c FDwfDeviceTriggerPC
		trigsrcDetectorAnalogIn  = 2   % AnalogIn's level/edge/pulse detector
		trigsrcDetectorDigitalIn = 3   % DigitalIn's pattern detector
		trigsrcAnalogIn          = 4   % fires when AnalogIn instrument enters Triggered state
		trigsrcDigitalIn         = 5   % fires when DigitalIn   instrument enters Triggered state
		trigsrcDigitalOut        = 6   % fires when DigitalOut  instrument is running
		trigsrcAnalogOut1        = 7   % fires when AnalogOut ch1 is running
		trigsrcAnalogOut2        = 8   % fires when AnalogOut ch2 is running
		trigsrcExternal1         = 11  % AD1 BNC T1 input
		trigsrcExternal2         = 12  % AD1 BNC T2 input
		trigsrcHigh              = 15  % constant high (use to "disable" a trigger pin)
		trigsrcLow               = 16  % constant low

		% Instrument states (some values are reused across instruments - see comments)
		DwfStateReady     = 0  % idle, configured but not started
		DwfStateConfig    = 4  % applying configuration
		DwfStatePrefill   = 5  % AnalogIn record mode - pre-trigger fill
		DwfStateArmed     = 1  % waiting for trigger
		DwfStateWait      = 7  % AnalogOut - between Run and the next Repeat
		DwfStateTriggered = 3  % AnalogIn - trigger fired, capturing
		DwfStateRunning   = 3  % AnalogOut - generating  (same value as Triggered)
		DwfStateDone      = 2  % acquisition / generation complete
		DwfStateNotDone   = 6  % record mode - poll returned but acquisition continues

		% Enum-config capability queries (use with @c FDwfEnumConfigInfo)
		DECIAnalogInChannelCount  = 1
		DECIAnalogOutChannelCount = 2
		DECIAnalogIOChannelCount  = 3
		DECIAnalogInBufferSize    = 7
		DECIAnalogOutBufferSize   = 8

		% Acquisition modes
		acqmodeSingle     = 0  % one-shot: fill buffer, stop. Most common.
		acqmodeScanShift  = 1  % continuous: oscilloscope-style scroll (new samples on the right)
		acqmodeScanScreen = 2  % continuous: fill, then overwrite from the start (no scroll)
		acqmodeRecord     = 3  % streaming - poll @c AnalogInStatusRecord, no buffer wrap
		acqmodeOvers      = 4  % oversampled single
		acqmodeSingle1    = 5  % single-shot for one channel at higher rate

		% Decimation filter applied when sample rate < ADC rate
		filterDecimate = 0  % keep every Nth sample
		filterAverage  = 1  % mean of N samples
		filterMinMax   = 2  % keep per-bucket min and max (use @c AnalogInStatusNoise)

		% Trigger detector type
		trigtypeEdge       = 0  % rising/falling edge crossing the level
		trigtypePulse      = 1  % pulse-width: less/timeout/more (see @c triglen*)
		trigtypeTransition = 2  % slew-rate: time taken to cross the level

		% Trigger slope (which way the signal must cross the level)
		DwfTriggerSlopeRise   = 0
		DwfTriggerSlopeFall   = 1
		DwfTriggerSlopeEither = 2

		% Pulse-length condition (paired with trigtypePulse)
		triglenLess    = 0  % pulse shorter than threshold
		triglenTimeout = 1  % no edge within threshold (auto-trigger)
		triglenMore    = 2  % pulse longer than threshold

		% AnalogOut signal functions
		funcDC        = 0
		funcSine      = 1
		funcSquare    = 2
		funcTriangle  = 3
		funcRampUp    = 4
		funcRampDown  = 5
		funcNoise     = 6
		funcPulse     = 7
		funcTrapezium = 8
		funcSinePower = 9   % sin(t)*|sin(t)|^(p-1), with p set via symmetry
		funcCustom    = 30  % single-shot of an uploaded sample buffer
		funcPlay      = 31  % streamed sample feed (continuous, refilled from host)

		% AnalogIO node types (AD1: V+/V- supplies expose Enable + Voltage; Current is readback)
		analogioEnable      = 1
		analogioVoltage     = 2
		analogioCurrent     = 3

		% AnalogOut nodes - which signal layer of a channel a Set* call addresses
		AnalogOutNodeCarrier = 0  % the main waveform
		AnalogOutNodeFM      = 1  % frequency-modulation input
		AnalogOutNodeAM      = 2  % amplitude-modulation input

		% What the AnalogOut channel does between Run and Repeat (or after stopping)
		DwfAnalogOutIdleDisable = 0  % output high-Z / off
		DwfAnalogOutIdleOffset  = 1  % hold at the offset voltage
		DwfAnalogOutIdleInitial = 2  % hold at the first sample of the waveform
		DwfAnalogOutIdleHold    = 3  % hold at the last sample (added in newer SDK)

		% DwfParam - AD1-relevant subset
		DwfParamUsbPower  = 2
		DwfParamOnClose   = 4  % 0 continue, 1 stop, 2 shutdown
		DwfParamAudioOut  = 5
		DwfParamUsbLimit  = 6  % mA, -1 = no limit
	end

	methods
		function a = dwf(idxDevice)
			%> Opens an Analog Discovery and eagerly builds @c In, @c Out, @c IO
			%> channel arrays from the device's reported counts.
			%> @param idxDevice: 0-based index from @c Enum; -1 (default) = first available.
			if nargin < 1, idxDevice = -1; end
			AVP.HW.AD.dwf.ensureLoaded();
			p = libpointer('int32Ptr', int32(0));
			ok = calllib('dwf', 'FDwfDeviceOpen', int32(idxDevice), p);
			if ~ok || p.Value == 0
				error('AVP:HW:AD:dwf', 'FDwfDeviceOpen failed: %s', AVP.HW.AD.dwf.GetLastErrorMsg());
			end
			a.h = p.Value;

			nIn  = a.AnalogInChannelCount();
			nOut = a.AnalogOutCount();
			nIO  = a.AnalogIOChannelCount();
			a.In  = arrayfun(@(k) AVP.HW.AD.AnalogInChannel (a, k), 0:nIn -1);
			a.Out = arrayfun(@(k) AVP.HW.AD.AnalogOutChannel(a, k), 0:nOut-1);
			a.IO  = arrayfun(@(k) AVP.HW.AD.AnalogIOChannel (a, k), 0:nIO -1);
		end

		function delete(a)
			if ~isempty(a.bg)
				if ~isempty(a.bg.timer) && isvalid(a.bg.timer)
					stop(a.bg.timer); delete(a.bg.timer);
				end
				a.bg = [];
			end
			if ~isempty(a.h) && a.h ~= 0 && libisloaded('dwf')
				calllib('dwf', 'FDwfDeviceClose', a.h);
			end
			a.h = int32(0);
		end % delete

		%%%%%%%%%%%%%%%%%%%%%%%%% DEVICE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		function DeviceReset(a),                                a.Call(); end
		function DeviceEnableSet(a, fEnable),                   a.Call(int32(logical(fEnable))); end
		function DeviceAutoConfigureSet(a, n),                  a.Call(int32(n)); end %>< 0 off, 1 normal, 3 dynamic
		function n = DeviceAutoConfigureGet(a),                 n = a.GetValue('int32'); end
		function DeviceTriggerPC(a),                            a.Call(); end
		function DeviceParamSet(a, param, value),               a.Call(int32(param), int32(value)); end
		function v = DeviceParamGet(a, param)
			p = libpointer('int32Ptr', int32(0));
			a.CallExplicit('DeviceParamGet', int32(param), p);
			v = double(p.Value);
		end

		%%%%%%%%%%%%%%%%%%%%%%%%% ANALOG IN (Scope - device-wide) %%%%%%%%%%%%%%%

		function AnalogInReset(a),                              a.Call(); end
		function AnalogInConfigure(a, fReconfigure, fStart)
			a.Call(int32(logical(fReconfigure)), int32(logical(fStart)));
		end
		function AnalogInTriggerForce(a),                       a.Call(); end

		function sts = AnalogInStatus(a, fReadData)
			%> Pull device state; @p fReadData = true also pulls samples into the driver buffer.
			%> Per-channel sample readers live on @c a.In(k).Status*.
			if nargin < 2, fReadData = false; end
			p = libpointer('uint8Ptr', uint8(0));
			a.CallExplicit('AnalogInStatus', int32(logical(fReadData)), p);
			sts = double(p.Value);
		end
		function n  = AnalogInStatusSamplesLeft(a),             n  = a.GetValue('int32'); end
		function n  = AnalogInStatusSamplesValid(a),            n  = a.GetValue('int32'); end
		function ix = AnalogInStatusIndexWrite(a),              ix = a.GetValue('int32'); end
		function f  = AnalogInStatusAutoTriggered(a)
			p = libpointer('int32Ptr', int32(0));
			a.CallExplicit('AnalogInStatusAutoTriggered', p);
			f = logical(p.Value);
		end
		function [avail, lost, corrupt] = AnalogInStatusRecord(a)
			pA = libpointer('int32Ptr', int32(0));
			pL = libpointer('int32Ptr', int32(0));
			pC = libpointer('int32Ptr', int32(0));
			a.CallExplicit('AnalogInStatusRecord', pA, pL, pC);
			avail = double(pA.Value); lost = double(pL.Value); corrupt = double(pC.Value);
		end
		function AnalogInRecordLengthSet(a, sec),               a.Call(double(sec)); end
		function sec = AnalogInRecordLengthGet(a),              sec = a.GetValue('double'); end

		function rec = InitRecording(a, chIdx1, trigsrc, durationSec)
			%> Enforce the REQUIRED settings (acquisition mode = @c acqmodeRecord,
			%> enable mask matching @p chIdx1 exactly, staging FIFO at max,
			%> trigger source = @p trigsrc, record length = @p durationSec),
			%> then arm acquisition. With @c trigsrcNone (default) ARM and FIRE
			%> happen here; with any other source the device waits in
			%> @c DwfStateArmed until the trigger fires.
			%> Channels not in @p chIdx1 are disabled so they can't overflow the
			%> SDK's shared @c lost counter while no one drains them.
			%> @param chIdx1 1-based channel list. Default = currently-enabled
			%>   channels (errors if none).
			%> @param trigsrc trigger source. Accepts either:
			%>   - a numeric @c trigsrc* constant: @c ad.trigsrcPC
			%>   - the bare name as char/string:   @c 'PC'  (looked up as @c trigsrc<name>)
			%>   See the "Trigger sources" properties block for the list of names.
			%>   Default = @c trigsrcNone.
			%> @param durationSec recording length in seconds AFTER TRIGGER FIRES
			%>   (or after ARM in free-run). Maps to @c FDwfAnalogInRecordLengthSet.
			%>   Pass @c Inf or @c -1 for unbounded. If omitted, the device's
			%>   current setting is left untouched.
			%> @retval rec context struct (@c chIdx1, @c K).

			if nargin < 2 || isempty(chIdx1)
				chIdx1 = find(arrayfun(@(c) c.EnableGet(), a.In));
				if isempty(chIdx1)
					error('AVP:HW:AD:dwf:InitRecording', ...
						'no channel list given and no In channels are enabled');
				end
			end
			chIdx1 = chIdx1(:).';
			if nargin < 3 || isempty(trigsrc)
				trigsrc = AVP.HW.AD.dwf.trigsrcNone;
			elseif ischar(trigsrc) || isstring(trigsrc)
				trigsrc = AVP.HW.AD.dwf.(['trigsrc' char(trigsrc)]);
			end
			if nargin >= 4 && ~isempty(durationSec)
				if isinf(durationSec), durationSec = -1; end
				a.AnalogInRecordLengthSet(durationSec);
			end

			if any(chIdx1 < 1 | chIdx1 > numel(a.In))
				error('AVP:HW:AD:dwf:InitRecording', ...
					'channel indices must be 1..%d (got %s)', numel(a.In), mat2str(chIdx1));
			end

			% REQUIRED state: only listed channels enabled, record mode active,
			% staging FIFO at max so polling latency doesn't cost samples,
			% trigger source set explicitly.
			for k = 1:numel(a.In)
				a.In(k).EnableSet(any(chIdx1 == k));
			end
			a.AnalogInAcquisitionModeSet(AVP.HW.AD.dwf.acqmodeRecord);
			[~, sMax] = a.AnalogInBufferSizeInfo();
			a.AnalogInBufferSizeSet(sMax);
			a.AnalogInTriggerSourceSet(trigsrc);

			rec = struct('chIdx1', chIdx1, 'K', numel(chIdx1));
			a.AnalogInConfigure(true, true);
		end % InitRecording

		function [data, lost, corrupt] = DoRecording(a, rec, nSamples)
			%> Drain samples from the armed acquisition. If the trigger source
			%> is anything other than @c trigsrcNone, fire the trigger before
			%> calling (e.g. @c DeviceTriggerPC for @c trigsrcPC).
			%> @param rec context returned by @c InitRecording.
			%> @param nSamples per-channel sample count to drain. If omitted, the
			%>   function derives it from @c AnalogInRecordLengthGet * @c AnalogInFrequencyGet
			%>   (whole capture in one call). Errors if the record length is
			%>   infinite (-1) and @p nSamples wasn't given - chunked draining of
			%>   an infinite capture has to be sized by the caller.
			%> @retval data N×K double matrix (column k = channel @c rec.chIdx1(k));
			%>   row count may be < @p nSamples if the device reached @c DwfStateDone.
			%> @retval lost,corrupt cumulative SDK counters; non-zero ⇒ USB throughput hit.

			if nargin < 3 || isempty(nSamples)
				sec = a.AnalogInRecordLengthGet();
				if sec <= 0
					error('AVP:HW:AD:dwf:DoRecording', ...
						'AnalogInRecordLength is infinite (%g); pass nSamples explicitly', sec);
				end
				nSamples = round(sec * a.AnalogInFrequencyGet());
			end

			K       = rec.K;
			data    = NaN(nSamples, K);  %>< NaN-init: any rows we don't write stay as gap markers
			got     = 0;
			lost    = 0;
			corrupt = 0;

			while got < nSamples
				sts                       = a.AnalogInStatus(true);
				[avail, lostNow, corrNow] = a.AnalogInStatusRecord();
				corrupt = corrupt + corrNow;

				% Lost samples fell between the previous batch and the upcoming one.
				% Advance the cursor by lostNow so subsequent writes land at the
				% correct time index; the skipped slice keeps its NaN init.
				if lostNow > 0
					gap  = min(lostNow, nSamples - got);
					got  = got + gap;
					lost = lost + lostNow;
				end

				if avail == 0
					if sts == AVP.HW.AD.dwf.DwfStateDone, break; end
					continue;
				end
				take = min(avail, nSamples - got);
				if take <= 0, break; end  % filled by gaps alone
				for k = 1:K
					data(got+1:got+take, k) = a.In(rec.chIdx1(k)).StatusData(take);
				end
				got = got + take;
			end
			data = data(1:got, :);
		end % DoRecording

		function StartBackgroundRecording(a, rec, nSamples, period)
			%> Start a @c timer that drains the FIFO in the background. Acquisition
			%> is already armed by @c InitRecording; for triggered captures fire
			%> the trigger (e.g. @c DeviceTriggerPC) at the right moment. Returns
			%> immediately. Collect results with @c StopBackgroundRecording.
			%> Background polling runs on the main MATLAB thread between user
			%> commands (cooperative, not preemptive). The user's command line
			%> stays responsive between timer ticks, but each tick briefly blocks.
			%> @param rec context returned by @c InitRecording.
			%> @param nSamples per-channel target count. Default = derived from
			%>   @c AnalogInRecordLengthGet * @c AnalogInFrequencyGet (errors on
			%>   infinite record length).
			%> @param period timer period in seconds. Default 0.01 (10 ms) - keep
			%>   it well below the FIFO budget @c bufferSize / (K * fs).

			if nargin < 4 || isempty(period),   period   = 0.01; end
			if nargin < 3 || isempty(nSamples)
				sec = a.AnalogInRecordLengthGet();
				if sec <= 0
					error('AVP:HW:AD:dwf:StartBackgroundRecording', ...
						'AnalogInRecordLength is infinite (%g); pass nSamples explicitly', sec);
				end
				nSamples = round(sec * a.AnalogInFrequencyGet());
			end
			if ~isempty(a.bg)
				error('AVP:HW:AD:dwf:StartBackgroundRecording', ...
					'a background recording is already active - call StopBackgroundRecording first');
			end

			a.bg = struct('rec', rec, ...
				'data',     NaN(nSamples, rec.K), ...
				'got',      0, ...
				'lost',     0, ...
				'corrupt',  0, ...
				'nSamples', nSamples, ...
				'done',     false, ...
				'timer',    []);
			a.bg.timer = timer( ...
				'ExecutionMode', 'fixedSpacing', ...
				'Period',        period, ...
				'BusyMode',      'drop', ...
				'TimerFcn',      @(~,~) a.bgPoll(), ...
				'ErrorFcn',      @(~,~) []);
			start(a.bg.timer);
		end % StartBackgroundRecording

		function [data, lost, corrupt] = StopBackgroundRecording(a)
			%> Stop the background timer, drain any leftovers, return collected
			%> data. Same return semantics as @c DoRecording.
			if isempty(a.bg)
				error('AVP:HW:AD:dwf:StopBackgroundRecording', ...
					'no background recording active');
			end
			if ~isempty(a.bg.timer) && isvalid(a.bg.timer)
				stop(a.bg.timer);
				delete(a.bg.timer);
			end
			a.bgPoll();   % final drain
			data    = a.bg.data(1:a.bg.got, :);
			lost    = a.bg.lost;
			corrupt = a.bg.corrupt;
			a.bg    = [];
		end % StopBackgroundRecording

		function done = IsBackgroundRecordingDone(a)
			%> True if the background recording has hit its sample target or the
			%> device reached @c DwfStateDone.
			done = isempty(a.bg) || a.bg.done || a.bg.got >= a.bg.nSamples;
		end % IsBackgroundRecordingDone

		% Acquisition config
		function [hzMin, hzMax] = AnalogInFrequencyInfo(a)
			pMin = libpointer('doublePtr', 0); pMax = libpointer('doublePtr', 0);
			a.Call(pMin, pMax);
			hzMin = pMin.Value; hzMax = pMax.Value;
		end
		function AnalogInFrequencySet(a, hz),                   a.Call(double(hz)); end
		function hz = AnalogInFrequencyGet(a),                  hz = a.GetValue('double'); end
		function n  = AnalogInBitsInfo(a),                      n  = a.GetValue('int32'); end
		function [sMin, sMax] = AnalogInBufferSizeInfo(a)
			pMin = libpointer('int32Ptr', int32(0)); pMax = libpointer('int32Ptr', int32(0));
			a.Call(pMin, pMax);
			sMin = double(pMin.Value); sMax = double(pMax.Value);
		end
		function AnalogInBufferSizeSet(a, nSize),               a.Call(int32(nSize)); end
		function n  = AnalogInBufferSizeGet(a),                 n = a.GetValue('int32'); end
		function AnalogInAcquisitionModeSet(a, mode),           a.Call(int32(mode)); end
		function m  = AnalogInAcquisitionModeGet(a),            m = a.GetValue('int32'); end

		% Channel counts & device-wide range/offset info (the per-channel setters
		% are on AnalogInChannel - reached via a.In(k).RangeSet, etc.)
		function n = AnalogInChannelCount(a),                   n = a.GetValue('int32'); end
		function [vMin, vMax, n] = AnalogInChannelRangeInfo(a)
			pMin = libpointer('doublePtr', 0); pMax = libpointer('doublePtr', 0);
			pN   = libpointer('doublePtr', 0);
			a.Call(pMin, pMax, pN);
			vMin = pMin.Value; vMax = pMax.Value; n = pN.Value;
		end
		function steps = AnalogInChannelRangeSteps(a)
			p = libpointer('doublePtr', zeros(32,1));
			pN = libpointer('int32Ptr', int32(0));
			a.Call(p, pN);
			steps = p.Value(1:pN.Value);
		end
		function [vMin, vMax, n] = AnalogInChannelOffsetInfo(a)
			pMin = libpointer('doublePtr', 0); pMax = libpointer('doublePtr', 0);
			pN   = libpointer('doublePtr', 0);
			a.Call(pMin, pMax, pN);
			vMin = pMin.Value; vMax = pMax.Value; n = pN.Value;
		end

		% Trigger
		function AnalogInTriggerSourceSet(a, trigsrc),          a.Call(uint8(trigsrc)); end
		function s = AnalogInTriggerSourceGet(a),               s = a.GetValue('uint8'); end
		function AnalogInTriggerTypeSet(a, trigtype),           a.Call(int32(trigtype)); end
		function AnalogInTriggerChannelSet(a, idxCh),           a.Call(int32(idxCh)); end
		function AnalogInTriggerFilterSet(a, filter),           a.Call(int32(filter)); end
		function AnalogInTriggerConditionSet(a, slope),         a.Call(int32(slope)); end
		function [vMin, vMax, n] = AnalogInTriggerLevelInfo(a)
			pMin = libpointer('doublePtr', 0); pMax = libpointer('doublePtr', 0);
			pN   = libpointer('doublePtr', 0);
			a.Call(pMin, pMax, pN);
			vMin = pMin.Value; vMax = pMax.Value; n = pN.Value;
		end
		function AnalogInTriggerLevelSet(a, v),                 a.Call(double(v)); end
		function v = AnalogInTriggerLevelGet(a),                v = a.GetValue('double'); end
		function AnalogInTriggerPositionSet(a, sec),            a.Call(double(sec)); end
		function AnalogInTriggerHoldOffSet(a, sec),             a.Call(double(sec)); end
		function AnalogInTriggerAutoTimeoutSet(a, sec),         a.Call(double(sec)); end

		%%%%%%%%%%%%%%%%%%%%%%%%% ANALOG OUT (Wavegen - count only) %%%%%%%%%%%%%

		function n = AnalogOutCount(a),                         n = a.GetValue('int32'); end
		% Per-channel and per-node wavegen control is on AnalogOutChannel:
		%   a.Out(k).Reset(), .Configure(start), .Status(), .RunSet(sec), .WaitSet,
		%   .RepeatSet, .TriggerSourceSet, .TriggerSlopeSet, .IdleSet, .ModeSet,
		%   .NodeEnableSet(node, ...), .NodeFunctionSet, .NodeFrequencySet,
		%   .NodeAmplitudeSet, .NodeOffsetSet, .NodeSymmetrySet, .NodePhaseSet,
		%   .NodeDataSet(node, samples).

		%%%%%%%%%%%%%%%%%%%%%%%%% ANALOG IO (V+ / V-) %%%%%%%%%%%%%%%%%%%%%%%%%%

		function AnalogIOReset(a),                              a.Call(); end
		function AnalogIOConfigure(a),                          a.Call(); end %>< apply queued node sets
		function AnalogIOStatus(a),                             a.Call(); end %>< refresh readback values
		function AnalogIOEnableSet(a, fEnable),                 a.Call(int32(logical(fEnable))); end %>< master power-supply enable
		function f = AnalogIOEnableGet(a),                      f = logical(a.GetValue('int32')); end
		function n = AnalogIOChannelCount(a),                   n = a.GetValue('int32'); end
		% Per-channel node access on AnalogIOChannel:
		%   a.IO(k).NodeSet(idxNode, value), .NodeGet(idxNode), .NodeStatus(idxNode),
		%   .NodeCount(), .Name().
	end

	methods (Access = protected)
		function bgPoll(a)
			%> Timer callback: drain ONE batch of currently-available samples,
			%> then return so the next tick can fire. Looping until @c avail==0
			%> would block here for the full record duration, because at typical
			%> sample rates the device produces new samples as fast as we drain
			%> them - the loop never sees a "no samples available" moment.
			if isempty(a.bg), return; end
			rec = a.bg.rec;

			sts                       = a.AnalogInStatus(true);
			[avail, lostNow, corrNow] = a.AnalogInStatusRecord();
			a.bg.corrupt = a.bg.corrupt + corrNow;
			if lostNow > 0
				gap        = min(lostNow, a.bg.nSamples - a.bg.got);
				a.bg.got   = a.bg.got + gap;
				a.bg.lost  = a.bg.lost + lostNow;
			end
			if avail > 0
				take = min(avail, a.bg.nSamples - a.bg.got);
				if take > 0
					for k = 1:rec.K
						a.bg.data(a.bg.got+1:a.bg.got+take, k) = a.In(rec.chIdx1(k)).StatusData(take);
					end
					a.bg.got = a.bg.got + take;
				end
			end
			if a.bg.got >= a.bg.nSamples || sts == AVP.HW.AD.dwf.DwfStateDone
				a.bg.done = true;
				if ~isempty(a.bg.timer) && isvalid(a.bg.timer), stop(a.bg.timer); end
			end
		end % bgPoll

		function Call(a, varargin)
			%> Calls @c FDwf<caller>(@c a.h, varargin{:}) where <caller> is the
			%> name of the method that invoked @c Call (read from @c dbstack).
			%> No @c varargout: all device outputs are returned via libpointers
			%> set by the caller, so they need no capture here.
			AVP.HW.AD.dwf.callByName(dbstack(1), a.h, varargin{:});
		end

		function CallExplicit(a, name, varargin)
			%> Same dispatch as @c Call but with an explicit function name; use
			%> from methods where the wrapper allocates the output libpointer
			%> itself (avoids the @c dbstack lookup for negligible speed gain
			%> and clearer call sites in @c Status*/@c *Get methods).
			AVP.HW.AD.dwf.callByName(name, a.h, varargin{:});
		end

		function value = GetValue(a, type)
			%> One-libpointer-out-arg sugar for the dozens of @c FDwf<X>Get(h, T*)
			%> functions. Wrapper body becomes @c function v = XGet(a), v = a.GetValue('T'); end .
			p = libpointer([type 'Ptr'], 0);
			AVP.HW.AD.dwf.callByName(dbstack(1), a.h, p);
			value = p.Value;
		end
	end

	methods (Static)
		function ensureLoaded()
			%> Idempotent @c loadlibrary against the current WaveForms SDK install.
			if libisloaded('dwf'), return; end
			hfile = 'C:\Program Files (x86)\Digilent\WaveFormsSDK\inc\dwf.h';
			libdir = 'C:\Program Files (x86)\Digilent\WaveFormsSDK\lib\x64\';
			if ~isfile(hfile)
				error('AVP:HW:AD:dwf', 'dwf.h not found at %s', hfile);
			end
			if isfolder(libdir), addpath(libdir); end
			loadlibrary('dwf', hfile);
		end

		function unload()
			if libisloaded('dwf'), unloadlibrary('dwf'); end
		end

		function s = GetVersion()
			%> @retval s: dwf.dll version, e.g. "3.20.32"
			AVP.HW.AD.dwf.ensureLoaded();
			buf = blanks(32);
			[~, buf] = calllib('dwf', 'FDwfGetVersion', buf);
			s = strtrim(buf);
		end

		function s = GetLastErrorMsg()
			if ~libisloaded('dwf'), s = '(dwf.dll not loaded)'; return; end
			buf = blanks(512);
			[~, buf] = calllib('dwf', 'FDwfGetLastErrorMsg', buf);
			s = strtrim(buf);
		end

		function n = Enum(filter)
			%> @param filter: see @c enumfilter* constants. Default = @c enumfilterAll.
			%>   To filter by device type in the new SDK, OR @c enumfilterType with a
			%>   @c devid*: @code n = AVP.HW.AD.dwf.Enum(bitor(enumfilterType, devidDiscovery)); @endcode
			if nargin < 1, filter = AVP.HW.AD.dwf.enumfilterAll; end
			AVP.HW.AD.dwf.ensureLoaded();
			p = libpointer('int32Ptr', int32(0));
			calllib('dwf', 'FDwfEnum', int32(filter), p);
			n = double(p.Value);
		end

		function [devId, devVer] = EnumDeviceType(idxDevice)
			AVP.HW.AD.dwf.ensureLoaded();
			pId  = libpointer('int32Ptr', int32(0));
			pVer = libpointer('int32Ptr', int32(0));
			calllib('dwf', 'FDwfEnumDeviceType', int32(idxDevice), pId, pVer);
			devId  = double(pId.Value);
			devVer = double(pVer.Value);
		end

		function name = EnumDeviceName(idxDevice)
			AVP.HW.AD.dwf.ensureLoaded();
			buf = blanks(32);
			[~, buf] = calllib('dwf', 'FDwfEnumDeviceName', int32(idxDevice), buf);
			name = strtrim(buf);
		end

		function sn = EnumSN(idxDevice)
			AVP.HW.AD.dwf.ensureLoaded();
			buf = blanks(32);
			[~, buf] = calllib('dwf', 'FDwfEnumSN', int32(idxDevice), buf);
			sn = strtrim(buf);
		end

		function f = EnumDeviceIsOpened(idxDevice)
			AVP.HW.AD.dwf.ensureLoaded();
			p = libpointer('int32Ptr', int32(0));
			calllib('dwf', 'FDwfEnumDeviceIsOpened', int32(idxDevice), p);
			f = logical(p.Value);
		end

		function ParamSet(param, value)
			%> Pre-open global parameter (e.g. @c DwfParamOnClose).
			AVP.HW.AD.dwf.ensureLoaded();
			calllib('dwf', 'FDwfParamSet', int32(param), int32(value));
		end

		function v = ParamGet(param)
			AVP.HW.AD.dwf.ensureLoaded();
			p = libpointer('int32Ptr', int32(0));
			calllib('dwf', 'FDwfParamGet', int32(param), p);
			v = double(p.Value);
		end
	end

	methods (Static, Hidden)
		function callByName(nameOrStack, varargin)
			%> Routes to @c calllib('dwf','FDwf<name>',...) where @c <name> is either
			%> passed in directly or derived from a @c dbstack(1) frame. Hidden but
			%> public so the channel classes (@c AnalogInChannel, etc.) can dispatch
			%> here without duplicating the calllib/error path.
			if isstruct(nameOrStack)
				parts = split(nameOrStack(1).name, '.');
				fname = parts{end};        % strip "ClassName." prefix if present
			else
				fname = nameOrStack;
			end
			funcName = ['FDwf' fname];
			ok = calllib('dwf', funcName, varargin{:});
			if ~ok
				error('AVP:HW:AD:dwf', '%s failed: %s', funcName, AVP.HW.AD.dwf.GetLastErrorMsg());
			end
		end
	end
end % dwf
