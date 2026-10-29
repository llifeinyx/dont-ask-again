# Don't Ask Again

A horror game about one long night shift at a CRT terminal. Godot 4.7.2, Forward+.

## Run

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) and [Git LFS](https://git-lfs.com/).
2. `git lfs install && git clone https://github.com/llifeinyx/dont-ask-again && cd dont-ask-again`
3. Open `project.godot` in Godot, or run `godot --path . -- --windowed`.

F11 switches between fullscreen and a window. F3 shows frame time in debug builds.

## Checks

`tools/check.sh` imports the project, compiles every script and scene, runs the unit tests, boots
the game on a virtual display and compares screenshots of fixed states with frames from Blender and with
approved goldens. It needs `xvfb-run` and a Vulkan driver. CI runs the same script on every pull request
and on `main`.

Rules for contributors and for Claude are in [CLAUDE.md](CLAUDE.md).
