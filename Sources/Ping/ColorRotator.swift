//
//  ColorRotator.swift
//  Ping
//
//  Created by Tanner on 3/4/26.
//

import Cocoa

struct ColorRotator {
  /// LRU order: front = next to show
  private var queue: [NSColor] = []
  private(set) var currentColor: NSColor?

  var isEmpty: Bool { currentColor == nil && queue.isEmpty }

  var hasMultipleColors: Bool {
    currentColor != nil && !queue.isEmpty
  }

  /// Update available colors. New colors go to front of queue,
  /// existing colors keep LRU order. Idempotent with same set.
  mutating func setAvailable(_ colors: [NSColor]) {
    guard !colors.isEmpty else {
      queue = []
      currentColor = nil
      return
    }

    // If we have no current color, start fresh
    guard let current = currentColor else {
      currentColor = colors.first
      queue = Array(colors.dropFirst())
      return
    }

    let allKnown = [current] + queue

    // Brand-new colors go to front (highest priority)
    var newQueue: [NSColor] = []
    for color in colors {
      if !allKnown.contains(where: { colorsEqual($0, color) }) {
        newQueue.append(color)
      }
    }

    // Existing queue colors still available keep their LRU order
    for color in queue {
      if colors.contains(where: { colorsEqual($0, color) }) {
        newQueue.append(color)
      }
    }

    queue = newQueue

    // If current was removed, pull next from queue
    if !colors.contains(where: { colorsEqual($0, current) }) {
      currentColor = queue.isEmpty ? nil : queue.removeFirst()
    }
  }

  /// Advance to next color. Returns the new current color.
  /// If only one color, returns current again. If empty, returns nil.
  mutating func next() -> NSColor? {
    guard let current = currentColor else { return nil }
    guard !queue.isEmpty else { return current }

    let next = queue.removeFirst()
    queue.append(current)
    currentColor = next
    return next
  }

  // MARK: - Private

  private func colorsEqual(_ a: NSColor, _ b: NSColor) -> Bool {
    guard let a = a.usingColorSpace(.sRGB),
      let b = b.usingColorSpace(.sRGB)
    else { return false }
    return abs(a.redComponent - b.redComponent) < 0.01
      && abs(a.greenComponent - b.greenComponent) < 0.01
      && abs(a.blueComponent - b.blueComponent) < 0.01
      && abs(a.alphaComponent - b.alphaComponent) < 0.01
  }
}
