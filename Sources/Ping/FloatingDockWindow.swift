import SwiftUI

class FloatingDockWindow: NSWindow {

  static func windowFrame(
    position: DockPosition, margin: Double, screen: NSRect
  ) -> NSRect {
    let windowHeight: CGFloat = 80
    let x = screen.origin.x + margin
    let width = screen.width - margin * 2
    let y: CGFloat
    switch position {
    case .topLeft, .topCenter, .topRight:
      y = screen.maxY - margin - windowHeight
    case .bottomLeft, .bottomCenter, .bottomRight:
      y = screen.origin.y + margin
    }
    return NSRect(x: x, y: y, width: width, height: windowHeight)
  }

  init(state: AppState, screen: NSRect) {
    let settings = state.floatingDockSettings
    let frame = Self.windowFrame(
      position: settings.position, margin: settings.margin, screen: screen)

    super.init(
      contentRect: frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: true
    )

    self.level = .statusBar
    self.isOpaque = false
    self.backgroundColor = .clear
    self.ignoresMouseEvents = true
    self.hasShadow = false
    self.collectionBehavior = [.canJoinAllSpaces, .stationary]

    let alignment: Alignment
    switch settings.position {
    case .topLeft, .bottomLeft: alignment = .leading
    case .topCenter, .bottomCenter: alignment = .center
    case .topRight, .bottomRight: alignment = .trailing
    }

    let view = FloatingDockView()
      .frame(maxWidth: .infinity, alignment: alignment)
      .environment(state)
    self.contentView = NSHostingView(rootView: view)
  }
}
