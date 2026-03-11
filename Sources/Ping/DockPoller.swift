import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: "Ping", category: "polling")

private struct BadgeOverride: Decodable {
  let appName: String
  let badge: String
}

@MainActor
class DockPoller {

  private let state: AppState
  private var pollingTask: Task<Void, Never>?

  init(state: AppState) {
    self.state = state
    pollingTask = Task {
      while !Task.isCancelled {
        self.poll()
        try? await Task.sleep(for: .seconds(self.state.refreshInterval))
      }
    }
  }

  private static let badgeOverrides: [String: String]? = {
    guard let json = ProcessInfo.processInfo.environment["BADGES"],
      let data = json.data(using: .utf8),
      let entries = try? JSONDecoder().decode([BadgeOverride].self, from: data)
    else { return nil }
    var dict: [String: String] = [:]
    for entry in entries { dict[entry.appName] = entry.badge }
    return dict
  }()

  private func poll() {
    let dockItems = DockItem.list()

    let names = dockItems.compactMap { $0.title }.sorted()
    if names != state.dockAppNames {
      state.dockAppNames = names
    }

    for item in dockItems {
      guard state.appIcons[item.title] == nil, let url = item.appURL else { continue }
      let icon = NSWorkspace.shared.icon(forFile: url.path)
      icon.size = NSSize(width: 32, height: 32)
      state.appIcons[item.title] = icon
    }

    var configs: [GlowConfig] = []
    var floatingDockItems: [FloatingDockItem] = []
    for app in state.apps {
      let badge: String?
      if let overrideBadge = Self.badgeOverrides?[app.name] {
        badge = overrideBadge
      } else if let dockItem = dockItems.first(where: { $0.title == app.name }) {
        badge = dockItem.badgeCount()
      } else {
        badge = nil
      }

      guard let badge else { continue }

      switch app.effect {
      case .glow:
        configs.append(AppState.resolvedConfig(for: app, badge: badge))
      case .floatingDock:
        floatingDockItems.append(
          FloatingDockItem(
            appName: app.name,
            badge: badge,
            icon: state.appIcons[app.name]
          ))
      }
    }

    state.activeGlowConfigs = configs
    state.activeFloatingDockApps = floatingDockItems
  }
}
