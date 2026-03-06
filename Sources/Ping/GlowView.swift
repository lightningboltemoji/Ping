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

  private var rotator = GlowConfigRotator()
  private var previewConfig: GlowConfig?
  private var displayedConfig: GlowConfig?

  private enum AnimationPhase {
    case idle
    case fadeIn
    case fadeOut
    case crossfade
  }

  private var phase: AnimationPhase = .idle

  private let baseMinOpacity: Float = 0.25
  private let baseMaxOpacity: Float = 0.95
  private var opacityMultiplier: Float = 1.0
  private var minOpacity: Float { baseMinOpacity * opacityMultiplier }
  private var maxOpacity: Float { baseMaxOpacity * opacityMultiplier }
  private let fadeDuration: CFTimeInterval = 2.0
  private let crossfadeDuration: CFTimeInterval = 0.4

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupGlowEffect()
    updateAvailableConfigs([])
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

  /// Update the set of configs to cycle through without interrupting the current animation.
  /// New configs are prioritized (shown next), existing configs maintain LRU order.
  func updateAvailableConfigs(_ newConfigs: [GlowConfig]) {
    let wasEmpty = rotator.isEmpty
    rotator.setAvailable(newConfigs)

    // During preview, rotator is silently updated but we don't touch animation
    if previewConfig != nil { return }

    if rotator.isEmpty {
      // All configs removed — fade out or go idle
      if phase != .idle {
        displayedConfig = nil
        phase = .idle
        glowLayer?.removeAllAnimations()
      }
      return
    }

    if wasEmpty || phase == .idle {
      // Start fresh
      displayedConfig = rotator.currentConfig
      if let config = displayedConfig {
        applyConfig(config)
        startFadeIn()
      }
      return
    }

    // If displayed config was removed from the set, accelerate fade-out
    if let displayed = displayedConfig,
      let current = rotator.currentConfig,
      displayed != current
    {
      accelerateTransitionAway()
    }
  }

  /// Show a preview config, interrupting normal cycling.
  func setPreviewConfig(_ config: GlowConfig) {
    previewConfig = config
    displayedConfig = config
    applyConfig(config)
    startFadeIn()
  }

  /// End preview and resume normal cycling.
  func clearPreview() {
    guard previewConfig != nil else { return }
    previewConfig = nil

    if let config = rotator.currentConfig {
      displayedConfig = config
      applyConfig(config)
      startFadeIn()
    } else {
      displayedConfig = nil
      phase = .idle
      glowLayer?.removeAllAnimations()
    }
  }

  // MARK: - Gradient

  private func gradientColors(for color: NSColor) -> [CGColor] {
    [
      color.cgColor,
      color.withAlphaComponent(0.15).cgColor,
      color.withAlphaComponent(0.0).cgColor,
    ]
  }

  private func applyConfig(_ config: GlowConfig) {
    opacityMultiplier = Float(config.opacity)
    glowLayer.colors = gradientColors(for: config.color)
    let s = CGFloat(config.size)
    glowLayer.locations = [0.0, 0.85, 1.0]
    glowLayer.endPoint = CGPoint(x: 0.8 + s / 5, y: 0.5 + s / 2)
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

  private func startCrossfade(to config: GlowConfig) {
    phase = .crossfade
    let oldColors = glowLayer.colors
    let oldEndPoint = glowLayer.endPoint
    displayedConfig = config
    let newColors = gradientColors(for: config.color)

    applyConfig(config)

    let colorsAnim = CABasicAnimation(keyPath: "colors")
    colorsAnim.fromValue = oldColors
    colorsAnim.toValue = newColors

    let endPointAnim = CABasicAnimation(keyPath: "endPoint")
    endPointAnim.fromValue = oldEndPoint
    endPointAnim.toValue = glowLayer.endPoint

    let group = CAAnimationGroup()
    group.animations = [colorsAnim, endPointAnim]
    group.duration = crossfadeDuration
    group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    group.delegate = self

    glowLayer.add(group, forKey: "glowAnimation")
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
      if previewConfig != nil {
        // Pulsing in preview mode
        startFadeIn()
      } else if rotator.isEmpty {
        phase = .idle
      } else if let next = rotator.next(),
        let displayed = displayedConfig,
        next != displayed
      {
        startCrossfade(to: next)
      } else {
        // Single config or same config — just pulse
        displayedConfig = rotator.currentConfig
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
