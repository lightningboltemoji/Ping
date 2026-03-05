//
//  SettingsView.swift
//  Ping
//
//  Created by Tanner on 9/28/25.
//

import SwiftUI

@available(macOS 26, *)
struct SettingsSection<Content: View>: View {
  let title: String?
  let trailing: AnyView?
  @ViewBuilder let content: () -> Content

  init(
    title: String? = nil,
    trailing: AnyView? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.trailing = trailing
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if title != nil || trailing != nil {
        HStack {
          if let title {
            Text(title)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(.secondary)
              .textCase(.uppercase)
          }
          Spacer()
          if let trailing {
            trailing
          }
        }
        .padding(.horizontal, 4)
      }
      VStack(spacing: 0) {
        content()
      }
      .background(.background.secondary)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
  }
}

@available(macOS 26, *)
struct AppCardView: View {
  @Binding var app: AppSettings
  let dockAppNames: [String]
  let onDelete: () -> Void
  let onHover: (Bool) -> Void

  var body: some View {
    VStack(spacing: 0) {
      // Identity row
      HStack(spacing: 8) {
        Circle()
          .fill(Color(nsColor: AppState.resolvedColor(for: app, badge: "")))
          .frame(width: 12, height: 12)

        Picker("App", selection: $app.name) {
          Text("Select app...").tag("")
          ForEach(dockAppNames, id: \.self) { name in
            Text(name).tag(name)
          }
        }
        .labelsHidden()
        .frame(maxWidth: .infinity)

        Picker("Color", selection: $app.color) {
          ForEach(AppState.colorPalette, id: \.name) { entry in
            HStack {
              Circle()
                .fill(Color(nsColor: entry.color))
                .frame(width: 10, height: 10)
              Text(entry.name)
            }
            .tag(entry.name)
          }
        }
        .labelsHidden()
        .frame(width: 110)

        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider().padding(.leading, 12)

      // Position row
      HStack {
        Text("Position")
          .foregroundStyle(.secondary)
        Spacer()
        Picker("Position", selection: $app.position) {
          ForEach(GlowPosition.allCases, id: \.self) { pos in
            Text(pos.rawValue.capitalized).tag(pos)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
        .labelsHidden()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider().padding(.leading, 12)

      // Size row
      HStack(spacing: 8) {
        Text("Size")
          .foregroundStyle(.secondary)
        Slider(value: $app.size, in: 0.05...1.0, step: 0.05)
        Text("\(Int(app.size * 100))%")
          .monospacedDigit()
          .frame(width: 40, alignment: .trailing)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider().padding(.leading, 12)

      // Opacity row
      HStack(spacing: 8) {
        Text("Opacity")
          .foregroundStyle(.secondary)
        Slider(value: $app.opacity, in: 0.1...1.0, step: 0.05)
        Text("\(Int(app.opacity * 100))%")
          .monospacedDigit()
          .frame(width: 40, alignment: .trailing)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider().padding(.leading, 12)

      // Per-type colors toggle
      HStack {
        Toggle("Color per notification type", isOn: $app.usePerTypeColors)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      if app.usePerTypeColors {
        Divider().padding(.leading, 12)

        // Numeric / Non-numeric color pickers
        HStack(spacing: 8) {
          Text("Numeric")
            .foregroundStyle(.secondary)
          Spacer()
          Picker("Numeric", selection: $app.numericColor) {
            ForEach(AppState.colorPalette, id: \.name) { entry in
              HStack {
                Circle()
                  .fill(Color(nsColor: entry.color))
                  .frame(width: 10, height: 10)
                Text(entry.name)
              }
              .tag(entry.name)
            }
          }
          .labelsHidden()
          .frame(width: 110)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        HStack(spacing: 8) {
          Text("Non-numeric")
            .foregroundStyle(.secondary)
          Spacer()
          Picker("Non-numeric", selection: $app.nonNumericColor) {
            ForEach(AppState.colorPalette, id: \.name) { entry in
              HStack {
                Circle()
                  .fill(Color(nsColor: entry.color))
                  .frame(width: 10, height: 10)
                Text(entry.name)
              }
              .tag(entry.name)
            }
          }
          .labelsHidden()
          .frame(width: 110)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
      }
    }
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .onHover { hovering in
      onHover(hovering)
    }
  }
}

@available(macOS 26, *)
struct SettingsView: View {

  @Environment(AppState.self) private var state

  var body: some View {
    @Bindable var state = state
    VStack(spacing: 0) {
      // Fixed header and general section
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 4) {
          Text("ping").font(.custom("Chango", size: 48))
          Text("Never miss a notification")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)

        // General section
        SettingsSection(title: "General") {
          HStack {
            Toggle(isOn: $state.launchOnStartup) {
              Text("Launch on startup")
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)

          Divider().padding(.leading, 12)

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text(
                String(
                  format: "Dock polling interval (%.1f sec)",
                  state.refreshInterval)
              )
              Slider(value: $state.refreshInterval, in: 0.1...5, step: 0.1)
                .labelsHidden()
            }
            Text(
              "A lower value detects notifications faster but uses more power"
            )
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 12)

      // Apps section header (fixed)
      HStack {
        Text("Apps")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
        Spacer()
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            state.apps.append(AppSettings(name: "", color: "Green"))
          }
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.system(size: 18))
            .foregroundStyle(.tint)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 6)

      // Scrollable apps list
      ScrollView {
        VStack(spacing: 12) {
          if state.apps.isEmpty {
            VStack(spacing: 8) {
              Image(systemName: "app.badge")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
              Text("No apps configured")
                .font(.headline)
                .foregroundStyle(.secondary)
              Text("Add a new app to monitor with +")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          } else {
            ForEach($state.apps) { $app in
              AppCardView(
                app: $app,
                dockAppNames: state.dockAppNames,
                onDelete: {
                  let id = app.id
                  withAnimation(.easeInOut(duration: 0.2)) {
                    state.apps.removeAll { $0.id == id }
                  }
                },
                onHover: { hovering in
                  if hovering {
                    state.previewGlowColor = AppState.resolvedColor(for: app, badge: "")
                  } else {
                    state.previewGlowColor = nil
                  }
                }
              )
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
    }
    .frame(maxWidth: 450, minHeight: 500, maxHeight: 700)
    .scenePadding()
  }
}
