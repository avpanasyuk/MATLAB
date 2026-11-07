function out = capture_triggered(varargin)
%> @file capture_triggered.m
%> @brief One-shot triggered analog capture on an Analog Discovery.
%>
%> Wraps the arm -> fire -> poll -> read sequence that every bring-up capture needs, so project
%> scripts carry only what is specific to their board. Handles the two things that are easy to get
%> wrong: waiting for a real trigger rather than accepting an auto-trigger, and still returning a
%> buffer (flagged) when the event never happened, so a null result is visible instead of silent.
%>
%> Name-value arguments (all optional):
%>   Channels   [1 2]   channels to enable, 1-based
%>   Range      5       input range V, per channel or scalar
%>   Offset     0       input offset V, per channel or scalar; centres the window off ground
%>   Rate       200e3   sample rate Hz
%>   TrigChan   1       trigger channel, 1-based (converted to DWF's 0-based internally)
%>   TrigLevel  1.0     trigger level V
%>   TrigCond   2       0 = rising, 1 = falling, 2 = either
%>   TrigPos    0       trigger position s relative to buffer centre; 0 = 50% pre-trigger
%>   HoldOff    0       trigger hold-off s
%>   Timeout    10      how long to wait for the trigger, s
%>   Fire       []      function handle invoked once armed, to cause the event
%>   Force      true    on timeout, force a capture so the idle trace is still returned
%>   Settle     0.4     s to wait for the offset DAC after a change; see below
%>   Filter     []      per-channel acquisition filter; [] leaves the device default
%>   Noise      false   also return the per-bucket min/max envelope; see below
%>
%> Returns a struct: y (samples x channels), t (s, 0 = trigger), Fs, triggered, auto, channels.
%> With Noise: also noiseMin / noiseMax (buckets x channels) and noiseT (bucket centres, s).
%>
%> Noise is opt-in because it changes what the device allocates, and this function is vendored by
%> a dozen projects that did not ask for it. Three measured properties of the underlying SDK calls
%> shape how it is wired, none of them guessable from dwf.h:
%>   - FDwfAnalogInNoiseSizeSet is an ENABLE FLAG, not a size - the magnitude is discarded.
%>   - The applied size is buffer/8, capped at 1024, and it materialises at FDwfAnalogInFrequencySet
%>     rather than at Configure. So the flag is set BELOW between BufferSizeSet and FrequencySet;
%>     after the FrequencySet it silently allocates nothing and StatusNoise then fails with
%>     "Invalid data count provided", far from the cause.
%>   - StatusNoise must be called with exactly the applied size, so this function reads it back and
%>     uses it. Never re-derive the count in a caller: buffer/8 is right until the 1024 cap bites.
%> Enabling the buffer does NOT require filterMinMax - the applied size is identical under
%> filterDecimate - but the ENVELOPE is only meaningful under filterMinMax, so pass
%> 'Filter', AVP.HW.AD.dwf.filterMinMax when you want to read it. The two are deliberately not
%> coupled here. Reference table (both libraries agreeing, measured): LAB_EQUIP's
%> instruments/analog-discovery-input-ranges.md, "The noise buffer".
%>
%> Offset moves the acquisition window off ground - a 0..12 V node needs Range 50 with Offset ~6,
%> because Range 5 only spans +-2.76 V. It costs a wait: the offset DAC slews with tau ~80 ms while
%> FDwfAnalogInConfigure returns at once and OffsetGet immediately echoes the COMMANDED value, so
%> there is nothing to poll. Worse, DWF adds the full requested offset to the reported volts in
%> software straight away, so an early read has a correct span sitting at a wrong absolute level.
%> Settle is therefore applied before arming whenever the requested offset differs from what the
%> device already holds, and skipped when it does not - a repeat capture pays nothing.
%>
%> Fire runs AFTER the scope is armed and its errors are caught, not propagated: the usual case is
%> a device that resets or stops answering because of the very event being captured, and that is a
%> normal outcome here, not a failure of the capture.
%>
%> Example - catch a supply dip and report how long the rail was below a threshold:
%>   out = AVP.HW.AD.capture_triggered('Channels',1,'Rate',200e3, ...
%>           'TrigChan',1,'TrigLevel',3.0,'TrigCond',1, ...
%>           'Fire',@() webread('http://board/do_the_thing', weboptions('Timeout',4)));
%>   fprintf('min %.3f V, longest run below 2.8 V: %.3f ms\n', min(out.y), ...
%>           AVP.HW.AD.longest_run(out.y < 2.8)/out.Fs*1e3);

p = inputParser;
p.addParameter('Channels', [1 2]);
p.addParameter('Range', 5);
p.addParameter('Offset', 0);
p.addParameter('Rate', 200e3);
p.addParameter('TrigChan', 1);
p.addParameter('TrigLevel', 1.0);
p.addParameter('TrigCond', 2);
p.addParameter('TrigPos', 0);
p.addParameter('HoldOff', 0);
p.addParameter('Timeout', 10);
p.addParameter('Fire', []);
p.addParameter('Force', true);
p.addParameter('Settle', 0.4);
p.addParameter('Filter', []);
p.addParameter('Noise', false);
p.parse(varargin{:});
a = p.Results;

chans = a.Channels(:).';
rng = a.Range;
if isscalar(rng), rng = repmat(rng, 1, numel(chans)); end
off = a.Offset;
if isscalar(off), off = repmat(off, 1, numel(chans)); end

ad = AVP.HW.AD.dwf();
% Read the offsets the device is physically holding BEFORE the reset commands them to 0, so a
% capture that is not moving the DAC can skip the settle entirely.
held = arrayfun(@(c) ad.In(c).OffsetGet(), chans);
ad.AnalogInReset();
for k = 1:numel(chans)
    ad.In(chans(k)).EnableSet(true);
    ad.In(chans(k)).RangeSet(rng(k));
    ad.In(chans(k)).OffsetSet(off(k));
    if ~isempty(a.Filter), ad.In(chans(k)).FilterSet(a.Filter); end
end
[~, smax] = ad.AnalogInBufferSizeInfo();
ad.AnalogInBufferSizeSet(smax);
% MUST precede the FrequencySet - that is what actually allocates the noise buffer. See the
% header: after it, this silently allocates nothing and StatusNoise fails much later.
if a.Noise, ad.AnalogInNoiseSizeSet(1); end
ad.AnalogInFrequencySet(a.Rate);
nNoise = 0;
if a.Noise, nNoise = ad.AnalogInNoiseSizeGet(); end
ad.AnalogInAcquisitionModeSet(ad.acqmodeSingle);
ad.AnalogInTriggerSourceSet(ad.trigsrcDetectorAnalogIn);
ad.AnalogInTriggerTypeSet(ad.trigtypeEdge);
ad.AnalogInTriggerChannelSet(a.TrigChan - 1);   % DWF indexes trigger channels from 0
ad.AnalogInTriggerConditionSet(a.TrigCond);
ad.AnalogInTriggerLevelSet(a.TrigLevel);
ad.AnalogInTriggerPositionSet(a.TrigPos);
ad.AnalogInTriggerHoldOffSet(a.HoldOff);
ad.AnalogInTriggerAutoTimeoutSet(0);            % never auto-trigger; wait for a real edge
ad.AnalogInConfigure(true, true);               % arm, which is also what applies the offset
settle = 0.05;                                  % enough on its own to reach DwfStateArmed
if any(abs(off - held) > 0.01), settle = max(settle, a.Settle); end
pause(settle);

if ~isempty(a.Fire)
    try
        a.Fire();
    catch ME
        fprintf('capture_triggered: Fire raised "%s" (expected if the event resets the target)\n', ME.message);
    end
end

t0 = tic;
while ad.AnalogInStatus(true) ~= ad.DwfStateDone && toc(t0) < a.Timeout
    pause(0.02);
end
out.triggered = (ad.AnalogInStatus(true) == ad.DwfStateDone);
if ~out.triggered && a.Force
    ad.AnalogInTriggerForce();
    pause(0.3);
end
% MUST re-read status after forcing. StatusData does not fetch anything - it returns whatever the
% most recent AnalogInStatus(true) snapshot holds (see AnalogInChannel.StatusData). Without this
% call the samples come from the pre-force snapshot, which is empty whenever the trigger never
% armed - e.g. a falling-edge level the signal starts below and so never crosses. That returns a
% constant and reads as a clean quiet trace rather than as a failure.
out.done = (ad.AnalogInStatus(true) == ad.DwfStateDone);
out.auto = ad.AnalogInStatusAutoTriggered();
out.Fs = ad.AnalogInFrequencyGet();
out.channels = chans;
out.y = zeros(smax, numel(chans));
for k = 1:numel(chans)
    out.y(:, k) = ad.In(chans(k)).StatusData(smax);
end
out.t = ((0:smax-1).' - smax/2) / out.Fs;       % s, 0 = trigger instant

if a.Noise
    out.noiseMin = zeros(nNoise, numel(chans));
    out.noiseMax = zeros(nNoise, numel(chans));
    for k = 1:numel(chans)
        [out.noiseMin(:, k), out.noiseMax(:, k)] = ad.In(chans(k)).StatusNoise(nNoise);
    end
    % Bucket centres on the same axis as out.t.
    out.noiseT = (((0:nNoise-1).' + 0.5) * (smax/nNoise) - smax/2) / out.Fs;
end

% A device that has lost USB enumeration hands back a constant rather than erroring, and a dead
% instrument reading as a clean, quiet signal is the worst failure this can have - it looks exactly
% like "the thing you were worried about is fine". Even a shorted input dithers by an LSB or two, so
% zero variance on every channel is never real data.
out.dead = all(var(out.y, 0, 1) == 0);
if out.dead
    warning('AVP:AD:deadCapture', ...
        ['All %d channel(s) returned zero variance (constant %.4f V) - the Analog Discovery is not ' ...
         'acquiring. Reseat its USB before believing anything. This is NOT a quiet signal.'], ...
        numel(chans), out.y(1, 1));
end
end
