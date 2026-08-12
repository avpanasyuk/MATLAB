# MATLAB

avpanasyuk's MATLAB utility library plus a few vendored regression toolboxes,
used by the analysis side of several projects (consumed as the `MATLAB/AVP_LIB`
submodule, e.g. in ElectricPanelMeter).

## Contents

- **`+AVP/`** — the author's own MATLAB package (utilities, reachable as `AVP.*`).
- **`+CONTRIB/`** — contributed / adapted helpers in package form (`CONTRIB.*`).
- **`ARESLab/`, `ARESLab.1.8.2/`** — ARESLab, the Adaptive Regression Splines (MARS) toolbox.
- **`M5PrimeLab/`** — M5'-style regression- / model-tree toolbox.
- **`LWP/`** — locally weighted polynomial regression.
- **`Objects/`, `START_and_FINISH/`** — class definitions and session start/cleanup helpers.
- **`MatlabDocMaker.m`** — documentation generator.

## Use

Add the repo root to your MATLAB path; the `+AVP` / `+CONTRIB` packages are then
reachable as `AVP.*` / `CONTRIB.*`. The regression toolboxes (ARESLab, M5PrimeLab,
LWP) are vendored third-party packages — see their own license / readme files.
