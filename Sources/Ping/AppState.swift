import AppKit
import SwiftUI

enum GlowPosition: String, Codable, CaseIterable {
  case top, bottom, left, right
}

enum ColorOptions: String, Codable, CaseIterable {
  case basic, advanced
}

enum Effect: String, Codable, CaseIterable {
  case glow
  case floatingDock

  var label: String {
    switch self {
    case .glow: "Glow"
    case .floatingDock: "Floating Dock"
    }
  }
}

enum GlowColor: String, CaseIterable, Codable {
  case red = "Red"
  case orange = "Orange"
  case yellow = "Yellow"
  case green = "Green"
  case blue = "Blue"
  case purple = "Purple"
  case pink = "Pink"
  case white = "White"

  var nsColor: NSColor {
    switch self {
    case .red: NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)
    case .orange: NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)
    case .yellow: NSColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.9)
    case .green: NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)
    case .blue: NSColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.9)
    case .purple: NSColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 0.9)
    case .pink: NSColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 0.9)
    case .white: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    }
  }
}

struct GlowAppearance: Codable, Equatable {
  var position: GlowPosition = .bottom
  var size: Double = 1.0
  var opacity: Double = 1.0
  var color: GlowColor = .green
}

struct GlowSettings: Codable, Equatable {
  var settingsMode: ColorOptions = .basic
  var normal: GlowAppearance = GlowAppearance()
  var nonNumeric: GlowAppearance = GlowAppearance()

  enum CodingKeys: String, CodingKey {
    case settingsMode = "settings_mode"
    case normal
    case nonNumeric = "non_numeric"
    // Legacy flat format keys
    case position, size, opacity, color
    case colorOption = "color_option"
    case nonNumericColor = "non_numeric_color"
  }

  init(
    settingsMode: ColorOptions = .basic,
    normal: GlowAppearance = .init(),
    nonNumeric: GlowAppearance = .init()
  ) {
    self.settingsMode = settingsMode
    self.normal = normal
    self.nonNumeric = nonNumeric
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let mode = try container.decodeIfPresent(ColorOptions.self, forKey: .settingsMode) {
      settingsMode = mode
    } else if let legacy = try container.decodeIfPresent(String.self, forKey: .colorOption),
      let mode = ColorOptions(rawValue: legacy)
    {
      settingsMode = mode
    } else {
      settingsMode = .basic
    }

    if let n = try container.decodeIfPresent(GlowAppearance.self, forKey: .normal) {
      normal = n
    } else {
      normal = GlowAppearance(
        position: try container.decodeIfPresent(GlowPosition.self, forKey: .position) ?? .bottom,
        size: try container.decodeIfPresent(Double.self, forKey: .size) ?? 1.0,
        opacity: try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0,
        color: try container.decodeIfPresent(GlowColor.self, forKey: .color) ?? .green
      )
    }

    if let nn = try container.decodeIfPresent(GlowAppearance.self, forKey: .nonNumeric) {
      nonNumeric = nn
    } else if let nnColor = try container.decodeIfPresent(String.self, forKey: .nonNumericColor),
      let glowColor = GlowColor(rawValue: nnColor)
    {
      nonNumeric = GlowAppearance(
        position: normal.position, size: normal.size, opacity: normal.opacity, color: glowColor)
    } else {
      nonNumeric = normal
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(settingsMode, forKey: .settingsMode)
    try container.encode(normal, forKey: .normal)
    try container.encode(nonNumeric, forKey: .nonNumeric)
  }
}

struct FloatingDockSettings: Codable, Equatable {
  var showAppName: Bool = true

  enum CodingKeys: String, CodingKey {
    case showAppName = "show_app_name"
  }
}

struct AppSettings: Codable, Equatable, Identifiable {
  var id = UUID()
  var name: String
  var effect: Effect = .glow
  var glowSettings: GlowSettings = GlowSettings()
  var floatingDockSettings: FloatingDockSettings = FloatingDockSettings()

  enum CodingKeys: String, CodingKey {
    case name
    case effect
    case glowSettings = "glow_settings"
    case floatingDockSettings = "floating_dock_settings"
  }
}

@Observable
class AppState {

  static func resolvedAppearance(for app: AppSettings, badge: String) -> GlowAppearance {
    let glow = app.glowSettings
    if glow.settingsMode == .advanced && badge.isEmpty {
      return glow.nonNumeric
    }
    return glow.normal
  }

  static func resolvedColor(for app: AppSettings, badge: String) -> NSColor {
    let appearance = resolvedAppearance(for: app, badge: badge)
    return appearance.color.nsColor.withAlphaComponent(appearance.opacity)
  }

  static func resolvedConfig(for app: AppSettings, badge: String) -> GlowConfig {
    let appearance = resolvedAppearance(for: app, badge: badge)
    return GlowConfig(
      color: appearance.color.nsColor.withAlphaComponent(appearance.opacity),
      size: appearance.size, opacity: appearance.opacity,
      position: appearance.position)
  }

  var launchOnStartup = false
  var refreshInterval = 1.0
  var apps: [AppSettings] = []
  var dockAppNames: [String] = []
  var appIcons: [String: NSImage] = [:]
  var activeGlowConfigs: [GlowConfig] = []
  var previewGlowConfig: GlowConfig? = nil
}
