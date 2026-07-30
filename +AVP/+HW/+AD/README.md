# `AVP.HW.AD` — driving a Digilent Analog Discovery from MATLAB

Thin MATLAB wrapper over the WaveForms SDK (`C:\Program Files (x86)\Digilent\WaveFormsSDK\`).
Use it to see what a pin, bus or supply rail **actually does** on a live board — UART, SWI/1-Wire,
SPI, or an analog rail during a transient. Input impedance is ~50 MΩ, so it does not load what it
watches.

`dwf.m` maps method names 1:1 onto the SDK's `FDwf*` functions (a method `XYZ` calls `FDwfXYZ`),
and carries the SDK's enums as constants — `acqmode*`, `trigsrc*`, `trigtype*`, `DwfState*`. Read
its header comment for the instrument state machine; it is the reference, not this file.

## Use `capture_triggered` for one-shot captures

Do not hand-roll the arm → fire → poll → read sequence in each project. `capture_triggered` is the
shared version:

```matlab
addpath('D:\Dropbox\personal\GIT_REPS\LIBS\MATLAB');
out = AVP.HW.AD.capture_triggered( ...
    'Channels', [1 2], 'Rate', 200e3, ...
    'TrigChan', 1, 'TrigLevel', 3.0, 'TrigCond', 1, ...   % 1 = falling: hunting a dip
    'Fire', @() webread('http://board/do_the_thing', weboptions('Timeout', 4)));
fprintf('triggered=%d  min %.3f V\n', out.triggered, min(out.y(:,1)));
```

It returns `y` (samples × channels), `t` (s, **0 = the trigger instant**), `Fs`, `triggered` and
`auto`. Two behaviours worth knowing:

- **Auto-trigger is disabled** (`AnalogInTriggerAutoTimeoutSet(0)`), so a capture only completes on
  a real edge. If the event never happens you get `triggered = 0` and a forced buffer of the idle
  signal — a null result you can see, rather than a plausible-looking trace of nothing.
- **`Fire` runs after the scope is armed, and its errors are caught.** The usual case is a target
  that resets or stops answering *because of* the event being captured; that is the expected
  outcome, not a failure.
- **`out.dead` flags a non-acquiring instrument.** An Analog Discovery that has lost USB
  enumeration returns a *constant* instead of erroring, and a dead instrument reading as a clean
  quiet signal is the worst failure this can have — it looks exactly like "the thing you were
  worried about is fine". Even a shorted input dithers by an LSB, so zero variance on every channel
  is never real data. Check `out.dead` before drawing any conclusion from a suspiciously clean
  trace; the fix is to reseat the USB.

`longest_run(mask)` gives the longest consecutive run in samples. For a supply dip this is the
statistic that matters — total time below a threshold conflates one long excursion with many short
ones, and only the longest single run says whether a reservoir capacitor could have covered it.

## Picking a sample rate

Match it to the shortest feature you must resolve, then check the span the buffer gives you
(`span = buffer / rate`; the AD's one-shot buffer is a few k samples per channel):

| what you are watching | rate | why |
|---|---|---|
| SWI / 1-Wire bit timing (µs pulses) | 50 MS/s | resolves sub-µs edges |
| 9600 baud UART | ~1 MS/s | ~100 samples per bit |
| supply rail transient / brownout | 200 kS/s | 5 µs resolution, still tens of ms of span |

## Triggering on something that has not happened yet

For an event you cause (a command, a motion, a reset), arm first and fire second — that is exactly
what the `Fire` parameter is for. Set `TrigPos` to 0 to put the trigger at the buffer centre and
keep 50% pre-trigger, so you see the approach as well as the event.

`TrigCond` is `0` rising, `1` falling, `2` either. Either-edge is the robust default when you only
need to catch activity; pick a direction when you are hunting a specific excursion.

## Running it headless

MATLAB raises its own window, so a `-batch` run steals focus unless suppressed. The launch recipe,
including the argument-splitting trap that silently drops everything after the first space in the
`-batch` token, is in **`GIT_REPS/PROJECTS/CLAUDE.md`** under *Bench debugging tools*. Write a
`.m` file and `run()` it; never inline multi-statement code.
