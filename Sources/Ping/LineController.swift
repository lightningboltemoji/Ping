import SwiftUI

@MainActor
class LineController {
  private let state: AppState
  private let screen: NSScreen?
  private var windows: [GlowPosition: LineWindow] = [:]

  init(state: AppState, screen: NSScreen?) {
    self.state = state
    self.screen = screen
    handleConfigChange(state.activeLineConfigs)
    observeConfigs()
    observeLineSettings()
    observePreview()
    observeSnooze()
  }

  private func window(for position: GlowPosition) -> LineWindow? {
    if let existing = windows[position] { return existing }
    guard let screen = screen else { return nil }
    let w = LineWindow(screen: screen, position: position)
    w.hideLine()
    windows[position] = w
    return w
  }

  private func observeConfigs() {
    withObservationTracking {
      _ = state.activeLineConfigs
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeLineConfigs)
        self.observeConfigs()
      }
    }
  }

  private func observeLineSettings() {
    withObservationTracking {
      _ = state.lineSettings
    } onChange: {
      Task { @MainActor in
        self.reResolveConfigs()
        self.observeLineSettings()
      }
    }
  }

  private func reResolveConfigs() {
    var configs: [GlowConfig] = []
    for app in state.apps where app.effect == .line {
      guard let badge = state.currentBadges[app.name] else { continue }
      configs.append(
        AppState.resolvedLineConfig(for: app, badge: badge, lineSettings: state.lineSettings))
    }
    state.activeLineConfigs = configs
  }

  private func observePreview() {
    withObservationTracking {
      _ = state.previewLineConfigs
    } onChange: {
      Task { @MainActor in
        let configs = self.state.previewLineConfigs
        if !configs.isEmpty {
          let grouped = Dictionary(grouping: configs, by: { $0.position })
          for (position, posConfigs) in grouped {
            let w = self.window(for: position)
            w?.setPreviewConfigs(posConfigs)
            w?.showLine()
          }
          for (pos, win) in self.windows where grouped[pos] == nil {
            win.clearPreview()
            if self.state.activeLineConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideLine()
            }
          }
        } else {
          for (pos, win) in self.windows {
            win.clearPreview()
            if self.state.activeLineConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideLine()
            }
          }
        }
        self.observePreview()
      }
    }
  }

  private func observeSnooze() {
    withObservationTracking {
      _ = state.snoozedUntil
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeLineConfigs)
        self.observeSnooze()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    if state.isSnoozed {
      for (_, win) in windows {
        win.updateConfigs([])
        win.hideLine()
      }
      return
    }

    let grouped = Dictionary(grouping: configs, by: { $0.position })

    for (position, posConfigs) in grouped {
      let w = window(for: position)
      w?.updateConfigs(posConfigs)
      w?.showLine()
    }

    for (position, win) in windows where grouped[position] == nil {
      win.updateConfigs([])
      win.hideLine()
    }
  }
}
