import Cocoa
import QuartzCore

class LineView: NSView {
  let position: GlowPosition

  private var configs: [GlowConfig] = []
  private var previewConfigs: [GlowConfig]?
  private var segmentLayers: [CALayer] = []

  init(frame frameRect: NSRect, position: GlowPosition) {
    self.position = position
    super.init(frame: frameRect)
    self.wantsLayer = true
  }

  required init?(coder: NSCoder) {
    self.position = .bottom
    super.init(coder: coder)
    self.wantsLayer = true
  }

  func updateConfigs(_ newConfigs: [GlowConfig]) {
    configs = newConfigs
    if previewConfigs == nil {
      rebuildSegments(from: configs)
    }
  }

  func setPreviewConfigs(_ newConfigs: [GlowConfig]) {
    previewConfigs = newConfigs
    rebuildSegments(from: newConfigs)
  }

  func clearPreview() {
    guard previewConfigs != nil else { return }
    previewConfigs = nil
    rebuildSegments(from: configs)
  }

  private func lineThickness(for size: Double) -> CGFloat {
    CGFloat(2.0 + size * 6.0)
  }

  private func rebuildSegments(from activeConfigs: [GlowConfig]) {
    CATransaction.begin()
    CATransaction.setAnimationDuration(0.3)
    CATransaction.setAnimationTimingFunction(
      CAMediaTimingFunction(name: .easeInEaseOut))

    let oldLayers = segmentLayers
    segmentLayers = []

    guard !activeConfigs.isEmpty else {
      for layer in oldLayers {
        layer.opacity = 0
      }
      CATransaction.setCompletionBlock {
        for layer in oldLayers {
          layer.removeFromSuperlayer()
        }
      }
      CATransaction.commit()
      return
    }

    let isHorizontal = position == .top || position == .bottom
    let totalLength = isHorizontal ? bounds.width : bounds.height
    let segmentLength = totalLength / CGFloat(activeConfigs.count)

    for (i, config) in activeConfigs.enumerated() {
      let thickness = lineThickness(for: config.size)
      let frame: CGRect
      if isHorizontal {
        let y: CGFloat = position == .bottom ? 0 : bounds.height - thickness
        frame = CGRect(
          x: CGFloat(i) * segmentLength, y: y,
          width: segmentLength, height: thickness)
      } else {
        let x: CGFloat = position == .left ? 0 : bounds.width - thickness
        frame = CGRect(
          x: x, y: CGFloat(i) * segmentLength,
          width: thickness, height: segmentLength)
      }

      let layer = CALayer()
      layer.frame = frame
      layer.backgroundColor =
        config.color.withAlphaComponent(config.opacity).cgColor
      layer.opacity = 1.0
      self.layer?.addSublayer(layer)
      segmentLayers.append(layer)
    }

    for layer in oldLayers {
      layer.opacity = 0
    }
    CATransaction.setCompletionBlock {
      for layer in oldLayers {
        layer.removeFromSuperlayer()
      }
    }
    CATransaction.commit()
  }

  override func layout() {
    super.layout()
    let active = previewConfigs ?? configs
    if !active.isEmpty {
      rebuildSegments(from: active)
    }
  }
}
