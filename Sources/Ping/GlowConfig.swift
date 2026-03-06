//
//  GlowConfig.swift
//  Ping
//

import Cocoa

struct GlowConfig: Equatable {
  let color: NSColor
  let size: Double
  let opacity: Double

  static func == (lhs: GlowConfig, rhs: GlowConfig) -> Bool {
    guard let a = lhs.color.usingColorSpace(.sRGB),
      let b = rhs.color.usingColorSpace(.sRGB)
    else { return false }
    return abs(a.redComponent - b.redComponent) < 0.01
      && abs(a.greenComponent - b.greenComponent) < 0.01
      && abs(a.blueComponent - b.blueComponent) < 0.01
      && abs(a.alphaComponent - b.alphaComponent) < 0.01
      && abs(lhs.size - rhs.size) < 0.01
      && abs(lhs.opacity - rhs.opacity) < 0.01
  }
}
