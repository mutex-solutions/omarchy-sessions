import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Sessions: workspaces and windows, per monitor.
//
// A "session" here is the set of workspaces currently on one monitor. Moving
// a session moves those workspaces, and the windows on them, to another
// monitor. Moving a window focuses it first, because Hyprland's window.move
// acts on the active window, then moves it to the target's active workspace.
Item {
  id: s

  Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // [{ id, name, focused, activeWorkspaceId, x, y, w, h, scale }]
  property var monitors: []
  // [{ id, name, monitor, windows }]
  property var workspaces: []
  // [{ address, title, class, workspaceId, workspaceName, monitorId,
  //    floating, mapped, hidden }]
  property var clients: []
  property string activeAddress: ""

  readonly property bool active: true
  readonly property string label: strings.t("sessions.sessions")
  readonly property string icon: "󰕮"

  readonly property var focusedMonitor: {
    for (var i = 0; i < monitors.length; i++)
      if (monitors[i].focused) return monitors[i]
    return monitors.length ? monitors[0] : null
  }

  function byName(name) {
    for (var i = 0; i < monitors.length; i++)
      if (monitors[i].name === name) return monitors[i]
    return null
  }

  // The monitor a window is on. Its workspace is the reliable answer; the
  // numeric monitor id is the fallback.
  function clientMonitor(c) {
    for (var i = 0; i < workspaces.length; i++)
      if (workspaces[i].id === c.workspaceId) return workspaces[i].monitor
    for (var j = 0; j < monitors.length; j++)
      if (monitors[j].id === c.monitorId) return monitors[j].name
    return ""
  }

  // One entry per monitor, focused first. Each carries its workspaces and the
  // visible windows that sit on it.
  readonly property var sessions: {
    var out = []
    var order = []
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].focused) order.push(monitors[i])
    }
    for (var k = 0; k < monitors.length; k++) {
      if (!monitors[k].focused) order.push(monitors[k])
    }

    for (var n = 0; n < order.length; n++) {
      var m = order[n]
      var ws = []
      for (var a = 0; a < workspaces.length; a++)
        if (workspaces[a].monitor === m.name) ws.push(workspaces[a])
      ws.sort(function(x, y) { return x.id - y.id })

      var wins = []
      for (var b = 0; b < clients.length; b++)
        if (clientMonitor(clients[b]) === m.name) wins.push(clients[b])

      out.push({
        name: m.name,
        focused: m.focused,
        activeWorkspaceId: m.activeWorkspaceId,
        workspaces: ws,
        windows: wins
      })
    }
    return out
  }

  readonly property int windowCount: clients.length

  readonly property string detail: {
    if (sessions.length === 0) return "no displays"
    // The half tile has one line; the display count is the page's job.
    return windowCount + (windowCount === 1 ? " window" : " windows")
  }

  function otherFor(name) {
    var destinations = destinationsFor(name)
    return destinations.length > 0 ? destinations[0] : ""
  }

  function destinationsFor(name) {
    var out = []
    for (var i = 0; i < monitors.length; i++)
      if (monitors[i].name !== name) out.push(monitors[i].name)
    return out
  }

  function workspaceIds(name) {
    var out = []
    for (var i = 0; i < workspaces.length; i++)
      if (workspaces[i].monitor === name) out.push(workspaces[i].id)
    out.sort(function(a, b) { return a - b })
    return out
  }

  function targetWorkspace(name) {
    var m = byName(name)
    return m ? m.activeWorkspaceId : 0
  }

  function luaStr(value) {
    return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
  }

  function applyLua(script) {
    if (!script || script === "") return
    Quickshell.execDetached(["hyprctl", "eval", script])
    settleTimer.restart()
  }

  // Move one window to the other monitor's active workspace. The window must
  // be active for window.move, so focus it, move it, then give focus back to
  // whatever the user was using.
  function moveWindow(address, toMonitor) {
    if (!address || !toMonitor) return
    var target = targetWorkspace(toMonitor)
    if (!target) return
    var lines = []
    lines.push('hl.dispatch(hl.dsp.focus({ window = "address:' + address + '" }))')
    lines.push('hl.dispatch(hl.dsp.window.move({ workspace = ' + target + ' }))')
    if (activeAddress && activeAddress !== address)
      lines.push('hl.dispatch(hl.dsp.focus({ window = "address:' + activeAddress + '" }))')
    applyLua(lines.join("\n"))
  }

  function workspaceById(id) {
    for (var i = 0; i < workspaces.length; i++) if (workspaces[i].id === id) return workspaces[i]
    return null
  }

  function moveDirection(fromName, toName) {
    var from = byName(fromName)
    var to = byName(toName)
    if (!from || !to) return ""
    if (to.x > from.x) return "r"
    if (to.x < from.x) return "l"
    if (to.y > from.y) return "d"
    if (to.y < from.y) return "u"
    return ""
  }

  function workspaceMoveLines(ids, toMonitor) {
    var lines = []
    for (var i = 0; i < ids.length; i++) {
      var ws = workspaceById(ids[i])
      if (!ws) continue
      var direction = moveDirection(ws.monitor, toMonitor)
      if (!direction) continue
      // Focus the requested workspace, then use Omarchy's own move primitive so
      // monitor-block adoption, source settling and focus invariants survive.
      lines.push('hl.dispatch(hl.dsp.focus({ workspace = "' + ids[i] + '" }))')
      lines.push('o.workspaces.move_to_monitor("' + direction + '")')
    }
    return lines
  }

  function moveWorkspace(id, toMonitor) {
    if (!id || !toMonitor) return
    applyLua(workspaceMoveLines([id], toMonitor).join("\n"))
  }

  // Move every workspace of one monitor to another. The windows follow their
  // workspaces; the ids are a snapshot before the first move.
  function moveSession(fromMonitor, toMonitor) {
    if (!fromMonitor || !toMonitor || fromMonitor === toMonitor) return
    applyLua(workspaceMoveLines(workspaceIds(fromMonitor), toMonitor).join("\n"))
  }

  // Exchange complete workspace sets, using Omarchy's primitive for each move.
  function swapSessions(a, b) {
    if (!a || !b || a === b) return
    var idsA = workspaceIds(a)
    var idsB = workspaceIds(b)
    var lines = workspaceMoveLines(idsA, b).concat(workspaceMoveLines(idsB, a))
    applyLua(lines.join("\n"))
  }

  function refresh() {
    if (!monitorProbe.running) monitorProbe.running = true
    if (!workspaceProbe.running) workspaceProbe.running = true
    if (!clientProbe.running) clientProbe.running = true
    if (!activeProbe.running) activeProbe.running = true
  }

  Process {
    id: monitorProbe
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var raw = JSON.parse(text || "[]")
          var out = []
          for (var i = 0; i < raw.length; i++) {
            var m = raw[i]
            out.push({
              id: Number(m.id || 0),
              name: String(m.name || ""),
              focused: m.focused === true,
              activeWorkspaceId: Number((m.activeWorkspace && m.activeWorkspace.id) || 0),
              activeWorkspaceName: String((m.activeWorkspace && m.activeWorkspace.name) || ""),
              x: Number(m.x || 0),
              y: Number(m.y || 0),
              w: Number(m.width || 0),
              h: Number(m.height || 0),
              scale: Number(m.scale || 1)
            })
          }
          s.monitors = out
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: workspaceProbe
    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var raw = JSON.parse(text || "[]")
          var out = []
          for (var i = 0; i < raw.length; i++) {
            var w = raw[i]
            if (Number(w.id || 0) <= 0) continue
            out.push({
              id: Number(w.id || 0),
              name: String(w.name || ""),
              monitor: String(w.monitor || ""),
              windows: Number(w.windows || 0)
            })
          }
          s.workspaces = out
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: clientProbe
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var raw = JSON.parse(text || "[]")
          var out = []
          for (var i = 0; i < raw.length; i++) {
            var c = raw[i]
            var ws = c.workspace || {}
            if (Number(ws.id || 0) <= 0) continue
            if (c.mapped === false || c.hidden === true) continue
            out.push({
              address: String(c.address || ""),
              title: String(c.title || ""),
              class: String(c.class || ""),
              workspaceId: Number(ws.id || 0),
              workspaceName: String(ws.name || ""),
              monitorId: Number(c.monitor || 0),
              floating: c.floating === true
            })
          }
          s.clients = out
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: activeProbe
    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var w = JSON.parse(text || "{}")
          s.activeAddress = String(w.address || "")
        } catch (e) {
          s.activeAddress = ""
        }
      }
    }
  }

  Timer {
    id: settleTimer
    interval: 700
    onTriggered: s.refresh()
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: s.refresh()
  }

  Component.onCompleted: refresh()
}
