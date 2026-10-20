# Sessions

Move windows, workspaces and whole sessions between displays. A bar widget, or
a section inside [Deck](https://github.com/mutex-solutions/omarchy-deck).

## What it does

A **session** is the set of workspaces a monitor currently holds. The page
lists each monitor's session, then every visible window on it:

- **Window → other display** moves one window to the other monitor's active
  workspace. Hyprland's `window.move` acts on the active window, so the page
  focuses the chosen window, moves it, and gives focus back to what you were
  using.
- **Workspace → other display** moves one workspace and all its windows.
- **Move session** moves every workspace on that monitor, so the whole block
  follows.
- **Swap sessions** exchanges the complete workspace sets of two monitors.
  The workspace ids are read before anything moves, so the second set is not
  the first set's leftovers.

The engine is Hyprland's own Lua dispatchers:
`hl.dsp.workspace.move({ workspace = id, monitor = ... })` and
`hl.dsp.window.move({ workspace = id })`, addressed by the window selector
`address:0x...`. No helper script is involved.

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

- The swap chip swaps the focused session with the first other one; with more
  than two monitors the page still offers per-window and per-session moves to
  each other monitor.
- Only workspaces Hyprland currently reports are moved. An empty workspace
  that has never been created does not exist to move.
- Special workspaces (scratchpads) are not part of a session and are not
  listed.

## Licence

MIT. See [LICENSE](LICENSE).
