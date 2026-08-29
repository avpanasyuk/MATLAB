# MATLAB

avpanasyuk's MATLAB utility library plus a few vendored regression toolboxes,
used by the analysis side of several projects (consumed as the `MATLAB/AVP_LIB`
submodule, e.g. in ElectricPanelMeter).

## Contents

- **`+AVP/`** — the author's own MATLAB package (utilities, reachable as `AVP.*`).
- **`+CONTRIB/`** — contributed / adapted helpers in package form (`CONTRIB.*`).
- **`ARESLab/`** — ARESLab, the Adaptive Regression Splines (MARS) toolbox
  (v1.13.0, May 2016 — the final upstream release).
- **`M5PrimeLab/`** — M5'-style regression- / model-tree toolbox.
- **`LWP/`** — locally weighted polynomial regression.
- **`START_and_FINISH/`** — session start/cleanup helpers.
- **`MatlabDocMaker.m`** — documentation generator.

## Use

Add the repo root to your MATLAB path; the `+AVP` / `+CONTRIB` packages are then
reachable as `AVP.*` / `CONTRIB.*`. The regression toolboxes (ARESLab, M5PrimeLab,
LWP) are vendored third-party packages (GPL-3.0) — see their own license / readme files.

## Branches

The default branch is `development`, where current work happens. `2Xi_V3` is
a frozen legacy snapshot.

Note: some local checkouts contain extra gitignored directories (e.g.
`ARESLab.1.10.1/`); these are local-only and not part of the repo.
