import SwiftUI

@MainActor
class GlowController {
  private let state: AppState
  private let screen: NSScreen?
  private var windows: [GlowPosition: GlowWindow] = [:]

  init(state: AppState, screen: NSScreen?) {
    self.state = state
    self.screen = screen
    handleConfigChange(state.activeGlowConfigs)
    observeConfigs()
    observePreview()
    observeSnooze()
  }

  private func window(for position: GlowPosition) -> GlowWindow? {
    if let existing = windows[position] { return existing }
    guard let screen = screen else { return nil }
    let w = GlowWindow(screen: screen, position: position)
    w.hideGlow()
    windows[position] = w
    return w
  }

  private func observeConfigs() {
    withObservationTracking {
      _ = state.activeGlowConfigs
    } onChange: {
      Task { @MainActor in
        self.handleConfigChange(self.state.activeGlowConfigs)
        self.observeConfigs()
      }
    }
  }

  private func observePreview() {
    withObservationTracking {
      _ = state.previewGlowConfig
    } onChange: {
      Task { @MainActor in
        if let config = self.state.previewGlowConfig {
          let w = self.window(for: config.position)
          w?.setPreviewConfig(config)
          w?.showGlow()
          for (pos, win) in self.windows where pos != config.position {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideGlow()
            }
          }
        } else {
          for (pos, win) in self.windows {
            win.clearPreview()
            if self.state.activeGlowConfigs.filter({ $0.position == pos }).isEmpty {
              win.hideGlow()
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
        self.handleConfigChange(self.state.activeGlowConfigs)
        self.observeSnooze()
      }
    }
  }

  private func handleConfigChange(_ configs: [GlowConfig]) {
    if state.isSnoozed {
      for (_, win) in windows {
        win.updateConfigs([])
        win.hideGlow()
      }
      return
    }

    let grouped = Dictionary(grouping: configs, by: { $0.position })

    for (position, posConfigs) in grouped {
      let w = window(for: position)
      w?.updateConfigs(posConfigs)
      w?.showGlow()
    }

    for (position, win) in windows where grouped[position] == nil {
      win.updateConfigs([])
      win.hideGlow()
    }
  }
}
