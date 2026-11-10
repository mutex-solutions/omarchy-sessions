# Sessions

Move windows, workspaces and whole sessions between displays. A bar widget, or
a section inside [Deck](https://github.com/mutex-solutions/omarchy-deck).

## What it does

A **session** is the set of workspaces a monitor currently holds. The page
lists each monitor's session, then every visible window on it:

- **Workspace → selected display** moves one workspace and all its windows.
- **Move session** moves every workspace on that monitor, so the whole block
  follows. With three or more monitors, a picker chooses the destination; the
  workspace ids are captured before anything moves.
- **Swap sessions** exchanges the complete workspace sets of the first two
  sessions (focused first).
- **Window → selected display** moves one window to that monitor's active
  workspace. Hyprland's `window.move` acts on the active window, so the page
  focuses the chosen window, moves it, and gives focus back to what you were
  using.

Workspace and session moves reuse Omarchy's `o.workspaces.move_to_monitor`
engine, which preserves monitor-block adoption, source settling and focus.
The selected display determines the direction passed to it. Window moves use
Hyprland's exact `hl.dsp.window.move` after focusing the requested address.
No helper script is involved.

## Standalone

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-sessions --enable
```

## Inside Deck

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-sessions
```

```json
{ "id": "sessions", "title": "Sessions",
  "file": "/home/YOU/.config/omarchy/plugins/mutex-solutions.sessions/deck/Section.qml",
  "page": "/home/YOU/.config/omarchy/plugins/mutex-solutions.sessions/deck/Page.qml" }
```

`install-bundle.sh` in the Deck repo wires this in with the other sections.

## Limits

- Omarchy's workspace move is **directional**. With three or more monitors in
  the same direction, it chooses the next display in that direction rather than
  guaranteeing the monitor named by the picker. Per-window moves are exact.
- The swap chip exchanges the first two sessions; with more than two monitors
  the other sessions still offer per-window, per-workspace and per-session moves.
- Only workspaces Hyprland currently reports are moved. An empty workspace
  that has never been created does not exist to move.
- Special workspaces (scratchpads) are not part of a session and are not
  listed.

## Licence

MIT. See [LICENSE](LICENSE).
