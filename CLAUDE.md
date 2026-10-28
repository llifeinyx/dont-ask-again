# Don't Ask Again

Arthouse horror game in Godot 4.7.2 (Forward+). The player works one night shift at a CRT terminal
running ND-OS; the frame "front" is the terminal on a desk, built from pre-rendered Blender light layers.

## Working with Zhan

- Talk to Zhan in Russian. Code, comments, commit messages, PR text and in-game text are in English.
- Zhan reviews and merges every PR into `main`. Work on a feature branch, never push to `main`.
- Each milestone of the foundation plan ends in one PR; the next starts only after it is merged.
- Before opening a PR, have a fresh reviewer agent read the diff and fix what it finds.
- Steps that need sudo or a password are done by Zhan.

## Sources of truth

- Design doc (game design, approved looks): https://docs.google.com/document/d/1gixYq_RmyAQ_G4VLbWzE_d4OHMZ4tLOQ7vG-oIVk98c/edit
  The doc never mentions this repository.
- Foundation plan (pipeline, structure, milestones M0–M5): https://claude.ai/artifact/7buecGDZDmTmEcS3X2JDN9
- M0 risk report (EXR, UV pass, tonemapping, cloud rendering): https://claude.ai/artifact/1odC44LfW52eDCntmp9wXo
- Figma: https://www.figma.com/design/IlHcXHo9w4TC7ITx3utRcp, page ND-OS, frame Desktop (1280×960 = 640×480 logical).

## Run and check

```bash
tools/ci/install_godot.sh          # pinned Godot 4.7.2 into ~/.cache/godot, linked as ~/.local/bin/godot
tools/check.sh                     # import, compile, unit tests, boot, screenshots compared with Blender and goldens
godot --path . -- --windowed       # play in a window
```

- `tools/check.sh` must pass before every commit; CI runs the same script on every pull request and on
  `main`, then fails if the checks left uncommitted files (usually a missing `.uid`). Logs and screenshots
  go to `$CHECK_OUT` (default `/tmp/dont-ask-again-check`). Each Godot run is killed after
  `$CHECK_TIMEOUT` seconds (default 300).
- The compile step loads every `.gd`, `.tscn` and `.tres`, so a file nothing uses yet still has to compile.
  A unit test fails on a failed check and on any error it logs, including runtime errors.
- The import, boot and screenshot steps run on a virtual display (`xvfb-run`) with a Vulkan driver. Without
  a GPU, `mesa-vulkan-drivers` gives lavapipe, which is enough for Forward+ screenshots but says nothing
  about speed. Import is not headless on purpose: with a rendering device Godot compresses the light layers
  to BC6H on the GPU in seconds, while `--headless` falls back to the CPU and takes over ten minutes.
- The boot step renders at 2560×1440 and saves `shots/boot.png`.
- Screenshot scenes in `tests/shots/` save fixed states (lamp on, flickering, off). `tests/compare_shots.gd`
  compares each with `tests/reference/` (from Blender, full size) when one exists and with `tests/golden/`
  (quarter size). A failing shot gets a `_diff.png` heat map. When a change of look is meant, run
  `UPDATE_GOLDEN=1 tools/check.sh`, look at the new goldens and commit them with the change.
- Launch flags go after `--`: `--windowed`, `--frames=N` (quit after N frames), `--shots=<dir>`
  (save screenshots of fixed states, then quit).
- Keys: F11 fullscreen/window. Debug builds only: F3 frame time overlay, F5 lamp mode (normal, flicker, off).
- Final look and frame time are checked on Zhan's PC (RX 9070 XT, CachyOS, fish shell) over Remote Control.
  The minimum target is 1080p60 on a GTX 1060 class GPU.

## Layout

```
project.godot
assets/
  front/           Blender export (never edit by hand): light layers, mug layers, glass UV pass, AgX LUT,
                   manifest.tres. The .import files next to them choose BC6H or lossless.
game/
  core/            things that live for the whole game: launch options, debug overlay (autoload Debug), LUT loader
  main/            entry scene, window and scaling
  front/           the front frame: composite and view shaders, FrontLighting, lighting presets, flicker
  shaders/         shader includes shared by several scenes
tests/
  test_case.gd     base class for unit tests
  run_tests.gd     runner: godot --headless --path . --script res://tests/run_tests.gd
  compile_all.gd   loads every script and scene; fails on any error
  compare_shots.gd compares screenshots with references and goldens
  error_log.gd     Logger that collects errors for the test tools
  unit/            test_*.gd, one file per script under test
  shots/           scenes that save screenshots of fixed states
  reference/       frames from Blender the game must match (not imported by Godot)
  golden/          approved screenshots at quarter size (not imported by Godot)
tools/
  check.sh         every check, locally and on CI
  ci/              CI helpers
  blender/         export_front.py, run in Blender on Zhan's PC
.github/workflows/ checks on push and PR
```

Coming with the next milestones (create a folder when it gets its first file):
`assets/ndos/` (icons, fonts, theme), `game/ndos/`, `game/glass/`, `assets/LICENSES.md`.

## Front export

`tools/blender/export_front.py` runs in Blender 5.2 on Zhan's PC over Remote Control, on
`crt_terminal_room.blend` (it stays on that PC, never in the repo):

```bash
blender -b crt_terminal_room.blend --python tools/blender/export_front.py -- --out <dir> [--preview]
```

It renders both view layers, writes everything listed in its docstring under `<dir>` laid out like the
repo, and never saves the .blend. Always run `--preview` first (25%, 32 samples) and wait for Zhan's
go before the full export. A full export goes straight into a clone of the repo (`--out <clone>`), then
gets committed with Git LFS from that PC. After a new export, run the checks and update the goldens.

## Code rules

- Scenes describe structure, scripts describe behaviour. Every part (front without ND-OS, ND-OS without
  glass) is its own scene that runs on its own. Parts talk through signals and the lighting node, never
  through each other's children.
- Strict GDScript: in `project.godot` every warning Godot enables by default is an error, and so are
  untyped declarations and unsafe access, casts and calls. Don't silence one with `@warning_ignore`
  unless there is no typed way to write the code, and say why in a comment.
  Give every variable, parameter and return a type; when a value comes from a `Variant` (dictionaries,
  `get()`, signals), declare the variable with an explicit type, not `:=`.
- ND-OS colours, fonts and spacing live in the theme and one tokens file that mirrors the Figma
  variables. Front light intensities and tints live in lighting presets. No magic numbers in scripts.
- All lighting maths is in linear colour. The frame is converted to display colour once, at the end of
  post-processing. Shared shader functions live in includes and are never copied.
- Autoloads only for what lives the whole game (settings, debug). Game state gets its own place later.
- No dead code and no buttons that do nothing. A stub is allowed only with a `# STUB:` comment and a
  matching task in the design doc's «Задачи».
- Debug-only code checks `OS.is_debug_build()` and never ships in release.
- snake_case for files, functions and variables, PascalCase for classes and nodes. Comments only where
  the code doesn't explain itself.
- Unit tests extend `TestCase`, live in `tests/unit/test_<name>.gd`, take no arguments and use `check` /
  `check_eq` (`check_eq` also compares types, so `1` and `1.0` differ).
  Cover the maths: coordinate mapping, layer sums, presets.
- Commit the `.uid` files Godot creates next to scripts. Never commit `.godot/` or builds.

## Front frame pipeline (facts from M0)

- One EXR per light group (lamp, screen, base, world, indicator), 16-bit half, ZIP compression,
  2816×1584 (2560×1440 plus 5% margin per side for camera sway). The mug is its own view layer with the same
  groups, premultiplied, blurred (foreground defocus) and cropped to `manifest.mug_rect`; its coverage is
  `mug_alpha.exr`. The frame is `room × (1 − mug_alpha) + mug`. Godot 4.7.2 does not read
  multilayer EXR or DWAA/DWAB/HTJ2K compression. EXR files go through Git LFS.
- The glass UV pass is 32-bit float, stored as (u·m, v·m, m) with a top-left origin; divide by m.
  16-bit is 12× less precise. It stays lossless; light layers are compressed to BC6H in VRAM.
- Tonemapping is a 65³ 3D LUT baked from Blender AgX + "AgX - Punchy" with a log2 shaper over
  [-12.47393, 12.5260688117]. Godot's built-in AgX is ~34/255 off and is not used.
- The test reference is the exported layers summed and run through Blender AgX, not Cycles' Combined.
- ND-OS renders in a 1280×960 SubViewport; a 1×1 SubViewport gives its average colour for the screen
  light layer. Clicks reach ND-OS through the same UV pass with `SubViewport.push_input(event, true)`.

## Don't

- Don't redesign looks Zhan approved (design doc §9); ask first.
- Don't run a final Blender render or export before Zhan has checked a low-sample preview.
- Don't skip, disable or weaken a check or a test to get green.
- Don't commit `.godot/`, builds, or files from Zhan's PC that aren't meant for the repo (`.blend` stays local).
