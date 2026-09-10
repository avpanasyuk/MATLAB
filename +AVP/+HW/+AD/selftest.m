function ok = selftest()
%> @file selftest.m
%> @brief Smoke test for the +AD wrappers. Run after any change to dwf.m or capture_triggered.m.
%>
%> Mirrors the Python side's scripts/ad_*_selftest.py. Checks the things that fail SILENTLY -- a
%> wrong return class, a buffer that allocates nothing, an envelope read from the wrong snapshot --
%> because those are what a reader cannot catch and what has actually bitten here:
%>   - the four char* wrappers rejected every call until cstrOut replaced blanks() (calllib: "Array
%>     must be numeric"), and one of them sits in the constructor's own error path, so it only
%>     surfaced once something else was already wrong;
%>   - AnalogInNoiseSizeGet returned int32, which turned capture_triggered's bucket-centre
%>     expression into integer division and rounded a whole time axis to zero.
%>
%> The first block needs only dwf.dll. The capture block needs an attached Analog Discovery and is
%> skipped with a notice if none enumerates, so this is safe to run anywhere.
%>
%> @retval ok true if every check passed.

fails = {};
    function check(name, cond)
        fprintf('  %-46s %s\n', name, string(logical(cond)));
        if ~cond, fails{end+1} = name; end %#ok<AGROW>
    end

fprintf('--- char* wrappers (dwf.dll only) ---\n');
v = AVP.HW.AD.dwf.GetVersion();
check('GetVersion is char',            ischar(v));
check('GetVersion has no NUL padding', ~any(v == 0));
check('GetVersion looks like a version', ~isempty(regexp(v, '^\d+\.\d+', 'once')));
fprintf('    version: "%s"\n', v);

% The path that used to throw instead of reporting: ask for a device index that cannot exist.
AVP.HW.AD.dwf.ensureLoaded();
calllib('dwf', 'FDwfDeviceOpen', int32(99), libpointer('int32Ptr', int32(0)));
msg = AVP.HW.AD.dwf.GetLastErrorMsg();
check('GetLastErrorMsg reports a real failure', ~isempty(msg));
fprintf('    SDK said: "%s"\n', strrep(msg, newline, ' / '));

n = AVP.HW.AD.dwf.Enum();
fprintf('  devices enumerated: %d\n', n);
if n > 0
    check('EnumDeviceName non-empty', ~isempty(AVP.HW.AD.dwf.EnumDeviceName(0)));
    check('EnumSN non-empty',         ~isempty(AVP.HW.AD.dwf.EnumSN(0)));
end

if n == 0
    fprintf('--- capture block SKIPPED: no Analog Discovery attached ---\n');
else
    fprintf('--- capture_triggered (needs the device) ---\n');
    % TrigLevel 99 can never be crossed, so Force returns the idle trace without waiting.
    d = AVP.HW.AD.capture_triggered('Channels',1,'Rate',200e3,'Timeout',1,'TrigLevel',99);
    check('default: no noise fields', ...
        ~isfield(d,'noiseMin') && ~isfield(d,'noiseMax') && ~isfield(d,'noiseT'));

    c = AVP.HW.AD.capture_triggered('Channels',[1 2],'Rate',200e3,'Timeout',1, ...
            'TrigLevel',99,'Noise',true,'Filter',AVP.HW.AD.dwf.filterMinMax);
    smax = size(c.y,1); nb = size(c.noiseMin,1);
    check('buckets == min(buffer/8, 1024)', nb == min(smax/8, 1024));
    check('envelope sized buckets x channels', ...
        isequal(size(c.noiseMax), [nb numel(c.channels)]));
    check('envelope non-negative everywhere', all(all(c.noiseMax - c.noiseMin >= 0)));
    % The int32 regression: an integer noiseT collapses to all zeros.
    check('noiseT is double',  isa(c.noiseT, 'double'));
    check('noiseT increasing', all(diff(c.noiseT) > 0));
    % Bucket centres are inset half a bucket at each end, so they sit strictly inside t and
    % still cover nearly all of it. Asserting equality with t(end) would be wrong, and
    % asserting the formula back would test nothing.
    check('noiseT inside t', c.noiseT(1) > c.t(1) && c.noiseT(end) < c.t(end));
    check('noiseT covers the capture', ...
        (c.noiseT(end) - c.noiseT(1)) > 0.9 * (c.t(end) - c.t(1)));
    fprintf('    buffer %d, buckets %d, envelope mean %.5f V\n', ...
        smax, nb, mean(c.noiseMax(:) - c.noiseMin(:)));

    e = AVP.HW.AD.capture_triggered('Channels',1,'Rate',200e3,'Timeout',1, ...
            'TrigLevel',99,'Noise',true);
    check('Noise without filterMinMax does not error', size(e.noiseMin,1) == nb);
end

ok = isempty(fails);
if ok
    fprintf('SELFTEST PASSED\n');
else
    fprintf('SELFTEST FAILED: %s\n', strjoin(fails, '; '));
end
end
