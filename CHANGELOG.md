# Changelog

## 0.1.3

- A hold on the 4x1 Sessionstile opens the Sessions page, matching the host gesture on non-custom tiles. The page no longer evaluates the swap label before both sessions exist.

## 0.1.2

- The Deck tile is neutral: Sessions is not a toggle, so it no longer takes
  the selected fill. Custom tiles also keep Deck's standard border now.

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

