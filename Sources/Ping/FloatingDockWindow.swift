import SwiftUI

class FloatingDockWindow: NSWindow {
  init(state: AppState, screen: NSRect) {
    let settings = state.floatingDockSettings
    let windowWidth = screen.width
    let windowHeight: CGFloat = 80

    let x: CGFloat
    let y: CGFloat

    switch settings.position {
    case .topLeft:
      x = screen.origin.x
      y = screen.maxY - settings.margin - windowHeight
    case .topCenter:
      x = screen.origin.x
      y = screen.maxY - settings.margin - windowHeight
    case .topRight:
      x = screen.origin.x
      y = screen.maxY - settings.margin - windowHeight
    case .bottomLeft:
      x = screen.origin.x
      y = screen.origin.y + settings.margin
    case .bottomCenter:
      x = screen.origin.x
      y = screen.origin.y + settings.margin
    case .bottomRight:
      x = screen.origin.x
      y = screen.origin.y + settings.margin
    }

    super.init(
      contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
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
      .padding(.horizontal, settings.margin)
      .environment(state)
    self.contentView = NSHostingView(rootView: view)
  }
}
