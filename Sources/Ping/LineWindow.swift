import Cocoa

class LineWindow: NSWindow {

  private var lineView: LineView!
  let position: GlowPosition

  private static let maxThickness: CGFloat = 8

  init(screen: NSScreen, position: GlowPosition) {
    self.position = position
    let sf = screen.frame
    let thickness = LineWindow.maxThickness

    let windowRect: NSRect
    switch position {
    case .bottom:
      windowRect = NSRect(
        x: sf.minX, y: sf.minY,
        width: sf.width, height: thickness)
    case .top:
      windowRect = NSRect(
        x: sf.minX, y: sf.maxY - thickness,
        width: sf.width, height: thickness)
    case .left:
      windowRect = NSRect(
        x: sf.minX, y: sf.minY,
        width: thickness, height: sf.height)
    case .right:
      windowRect = NSRect(
        x: sf.maxX - thickness, y: sf.minY,
        width: thickness, height: sf.height)
    }

    super.init(
      contentRect: windowRect,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = false
    self.level = NSWindow.Level.floating
    self.ignoresMouseEvents = true

    lineView = LineView(frame: windowRect, position: position)
    self.contentView = lineView
  }

  func updateConfigs(_ configs: [GlowConfig]) {
    lineView.updateConfigs(configs)
  }

  func setPreviewConfigs(_ configs: [GlowConfig]) {
    lineView.setPreviewConfigs(configs)
  }

  func clearPreview() {
    lineView.clearPreview()
  }

  func showLine() {
    self.makeKeyAndOrderFront(nil)
  }

  func hideLine() {
    self.orderOut(nil)
  }
}
