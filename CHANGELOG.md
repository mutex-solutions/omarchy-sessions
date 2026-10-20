# Changelog

## 0.1.1

- A **4x1 tile** (`tileFull`) lists each monitor's window count and active
  workspace; the 2x1 detail is now just the window count, which fits without
  clipping.

## 0.1.0

First release.

- Separate from Display: window and workspace management is its own section,
  leaving the Display page to arrangement, resolution, refresh rate, scale,
  brightness and text size.
- Per-monitor session blocks: workspaces and every visible window.
- Move one window, one workspace, or the whole session to another display.
- Swap the complete sessions of two displays.
- Uses Hyprland's Lua workspace/window dispatchers directly; no helper script.

