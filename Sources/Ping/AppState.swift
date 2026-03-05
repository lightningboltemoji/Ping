import AppKit
import SwiftUI

enum GlowPosition: String, Codable, CaseIterable {
  case top, bottom, left, right
}

struct AppSettings: Codable, Identifiable {
  var id = UUID()
  var name: String
  var color: String
  var position: GlowPosition = .top
  var size: Double = 0.25
  var opacity: Double = 0.9
  var usePerTypeColors: Bool = false
  var numericColor: String = "Green"
  var nonNumericColor: String = "Green"
}

@Observable
class AppState {

  static let colorPalette: [(name: String, color: NSColor)] = [
    ("Red", NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.9)),
    ("Orange", NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)),
    ("Yellow", NSColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.9)),
    ("Green", NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)),
    ("Blue", NSColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.9)),
    ("Purple", NSColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 0.9)),
    ("Pink", NSColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 0.9)),
    ("White", NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)),
  ]

  static func nsColor(forName name: String) -> NSColor {
    colorPalette.first(where: { $0.name.lowercased() == name.lowercased() })?.color
      ?? NSColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)
  }

  static func resolvedColor(for app: AppSettings, badge: String) -> NSColor {
    let name: String
    if app.usePerTypeColors {
      name = !badge.isEmpty ? app.numericColor : app.nonNumericColor
    } else {
      name = app.color
    }
    return nsColor(forName: name).withAlphaComponent(app.opacity)
  }

  var launchOnStartup = true
  var refreshInterval = 1.0
  var count = 0
  var apps: [AppSettings] = []
  var dockAppNames: [String] = []
  var activeGlowColors: [NSColor] = []
  var previewGlowColor: NSColor? = nil
}
