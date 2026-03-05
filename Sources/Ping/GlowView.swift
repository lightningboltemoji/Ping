//
//  GlowView.swift
//  Ping
//
//  Created by Tanner on 9/17/25.
//

import Cocoa
import QuartzCore

class GlowView: NSView, @preconcurrency CAAnimationDelegate {
  private var glowLayer: CAGradientLayer!

  private var rotator = ColorRotator()
  private var previewColor: NSColor?
  private var displayedColor: NSColor?

  private enum AnimationPhase {
    case idle
    case fadeIn
    case fadeOut
    case crossfade
  }

  private var phase: AnimationPhase = .idle

  private let minOpacity: Float = 0.25
  private let maxOpacity: Float = 0.95
  private let fadeDuration: CFTimeInterval = 2.0
  private let crossfadeDuration: CFTimeInterval = 0.6

  init(frame frameRect: NSRect, baseColor: NSColor) {
    super.init(frame: frameRect)
    setupGlowEffect()
    updateAvailableColors([baseColor])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGlowEffect()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    setupGlowEffect()
  }

  // MARK: - Public API

  /// Update the set of colors to cycle through without interrupting the current animation.
  /// New colors are prioritized (shown next), existing colors maintain LRU order.
  func updateAvailableColors(_ newColors: [NSColor]) {
    let wasEmpty = rotator.isEmpty
    rotator.setAvailable(newColors)

    // During preview, rotator is silently updated but we don't touch animation
    if previewColor != nil { return }

    if rotator.isEmpty {
      // All colors removed — fade out or go idle
      if phase != .idle {
        displayedColor = nil
        phase = .idle
        glowLayer?.removeAllAnimations()
      }
      return
    }

    if wasEmpty || phase == .idle {
      // Start fresh
      displayedColor = rotator.currentColor
      if let color = displayedColor {
        applyColor(color)
        startFadeIn()
      }
      return
    }

    // If displayed color was removed from the set, accelerate fade-out
    if let displayed = displayedColor,
      let current = rotator.currentColor,
      !colorsEqual(displayed, current)
    {
      accelerateTransitionAway()
    }
  }

  /// Show a preview color, interrupting normal cycling.
  func setPreviewColor(_ color: NSColor) {
    previewColor = color
    displayedColor = color
    applyColor(color)
    startFadeIn()
  }

  /// End preview and resume normal cycling.
  func clearPreview() {
    guard previewColor != nil else { return }
    previewColor = nil

    if let color = rotator.currentColor {
      displayedColor = color
      applyColor(color)
      startFadeIn()
    } else {
      displayedColor = nil
      phase = .idle
      glowLayer?.removeAllAnimations()
    }
  }

  // MARK: - Color helpers

  private func colorsEqual(_ a: NSColor, _ b: NSColor) -> Bool {
    guard let a = a.usingColorSpace(.sRGB),
      let b = b.usingColorSpace(.sRGB)
    else { return false }
    return abs(a.redComponent - b.redComponent) < 0.01
      && abs(a.greenComponent - b.greenComponent) < 0.01
      && abs(a.blueComponent - b.blueComponent) < 0.01
      && abs(a.alphaComponent - b.alphaComponent) < 0.01
  }

  // MARK: - Gradient

  private func gradientColors(for color: NSColor) -> [CGColor] {
    [
      color.cgColor,
      color.withAlphaComponent(0.15).cgColor,
      color.withAlphaComponent(0.0).cgColor,
    ]
  }

  private func applyColor(_ color: NSColor) {
    glowLayer.colors = gradientColors(for: color)
    glowLayer.locations = [0.0, 0.85, 1.0]
  }

  // MARK: - Setup

  private func setupGlowEffect() {
    self.wantsLayer = true

    glowLayer = CAGradientLayer()
    glowLayer.frame = self.bounds
    glowLayer.type = .radial

    glowLayer.startPoint = CGPoint(x: 0.5, y: 0)
    glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

    glowLayer.opacity = minOpacity
    self.layer?.addSublayer(glowLayer)
  }

  // MARK: - Animation

  private func startFadeIn() {
    phase = .fadeIn
    glowLayer?.removeAllAnimations()

    glowLayer.opacity = maxOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = minOpacity
    anim.toValue = maxOpacity
    anim.duration = fadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer?.add(anim, forKey: "glowAnimation")
  }

  private func startFadeOut() {
    phase = .fadeOut

    glowLayer.opacity = minOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = maxOpacity
    anim.toValue = minOpacity
    anim.duration = fadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer?.add(anim, forKey: "glowAnimation")
  }

  private func startCrossfade(to color: NSColor) {
    phase = .crossfade
    let oldColors = glowLayer.colors
    displayedColor = color
    let newColors = gradientColors(for: color)

    glowLayer.colors = newColors

    let anim = CABasicAnimation(keyPath: "colors")
    anim.fromValue = oldColors
    anim.toValue = newColors
    anim.duration = crossfadeDuration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer.add(anim, forKey: "glowAnimation")
  }

  private func accelerateTransitionAway() {
    guard phase != .crossfade else { return }

    let currentOpacity =
      glowLayer.presentation()?.opacity ?? glowLayer.opacity
    glowLayer.removeAllAnimations()

    let duration = max(
      0.15, Double(currentOpacity / maxOpacity) * fadeDuration * 0.5)

    phase = .fadeOut
    glowLayer.opacity = minOpacity

    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = currentOpacity
    anim.toValue = minOpacity
    anim.duration = duration
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    anim.delegate = self

    glowLayer.add(anim, forKey: "glowAnimation")
  }

  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    guard flag else { return }

    switch phase {
    case .idle:
      break
    case .fadeIn:
      startFadeOut()
    case .fadeOut:
      if previewColor != nil {
        // Pulsing in preview mode
        startFadeIn()
      } else if rotator.isEmpty {
        phase = .idle
      } else if let next = rotator.next(),
        let displayed = displayedColor,
        !colorsEqual(next, displayed)
      {
        startCrossfade(to: next)
      } else {
        // Single color or same color — just pulse
        displayedColor = rotator.currentColor
        startFadeIn()
      }
    case .crossfade:
      startFadeIn()
    }
  }

  override func layout() {
    super.layout()
    glowLayer?.frame = self.bounds
  }
}
