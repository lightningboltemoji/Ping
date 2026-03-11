import SwiftUI

struct FloatingDockView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    let items =
      state.previewFloatingDockApps.isEmpty
      ? state.activeFloatingDockApps : state.previewFloatingDockApps
    let settings = state.floatingDockSettings
    if !items.isEmpty {
      HStack(spacing: 12) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
          VStack(spacing: 4) {
            if let icon = item.icon {
              Image(nsImage: icon)
                .resizable()
                .frame(width: settings.iconSize, height: settings.iconSize)
            } else {
              Image(systemName: "app.fill")
                .resizable()
                .frame(width: settings.iconSize, height: settings.iconSize)
                .foregroundStyle(.secondary)
            }
            if settings.showAppNames {
              Text(item.appName)
                .font(.system(size: 10))
                .foregroundStyle(.primary)
                .lineLimit(1)
            }
          }
        }
      }
      .padding(.horizontal, settings.padding)
      .padding(.vertical, 10)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color(nsColor: settings.backgroundColor.nsColor).opacity(0.15))
          )
      }
      .opacity(settings.opacity)
    }
  }
}
