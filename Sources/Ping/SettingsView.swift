//
//  SettingsView.swift
//  Ping
//
//  Created by Tanner on 9/28/25.
//

import ServiceManagement
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
struct GlowAppearanceControls: View {
  @Binding var appearance: GlowAppearance

  var body: some View {

    // Color row
    HStack(spacing: 8) {
      Text("Color")
        .foregroundStyle(.secondary)
      Spacer()
      Picker("Color", selection: $appearance.color) {
        ForEach(GlowColor.allCases, id: \.self) { glowColor in
          HStack {
            Circle()
              .fill(Color(nsColor: glowColor.nsColor))
              .frame(width: 10, height: 10)
            Text(glowColor.rawValue)
          }
          .tag(glowColor)
        }
      }
      .labelsHidden()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)

    Divider().padding(.leading, 12)

    // Position row
    HStack {
      Text("Position")
        .foregroundStyle(.secondary)
      Spacer()
      Picker("Position", selection: $appearance.position) {
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
      Slider(value: $appearance.size, in: 0.25...1.0, step: 0.05)
      Text("\(Int(appearance.size * 100))%")
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
      Slider(value: $appearance.opacity, in: 0.4...1.0, step: 0.05)
      Text("\(Int(appearance.opacity * 100))%")
        .monospacedDigit()
        .frame(width: 40, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }
}

@available(macOS 26, *)
struct AppCardView: View {
  @Binding var app: AppSettings
  let dockAppNames: [String]
  let appIcons: [String: NSImage]
  let onDelete: () -> Void
  let onPreview: (GlowConfig?) -> Void
  let onFloatingDockPreview: (Bool) -> Void

  enum AdvancedTab: String, CaseIterable {
    case numeric, nonNumeric

    var label: String {
      switch self {
      case .numeric: "Numeric"
      case .nonNumeric: "Non-numeric"
      }
    }
  }

  @State private var isHovering = false
  @State private var advancedTab: AdvancedTab = .numeric

  private func updatePreview() {
    guard isHovering else {
      onPreview(nil)
      onFloatingDockPreview(false)
      return
    }
    switch app.effect {
    case .glow:
      onFloatingDockPreview(false)
      if app.glowSettings.settingsMode == .advanced {
        let badge = advancedTab == .nonNumeric ? "" : "1"
        onPreview(AppState.resolvedConfig(for: app, badge: badge))
      } else {
        onPreview(AppState.resolvedConfig(for: app, badge: ""))
      }
    case .floatingDock:
      onPreview(nil)
      onFloatingDockPreview(true)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Identity row
      HStack(spacing: 8) {
        if let icon = appIcons[app.name] {
          Image(nsImage: icon).resizable()
            .frame(width: 28, height: 28).padding(1)
        } else {
          Circle()
            .fill(Color(nsColor: AppState.resolvedColor(for: app, badge: "")))
            .frame(width: 22, height: 22)
            .padding(4)
        }
        Menu {
          Button("None") {
            app.name = ""
          }
          ForEach(dockAppNames, id: \.self) { name in
            Button {
              app.name = name
            } label: {
              if let icon = appIcons[name] {
                Image(nsImage: icon)
              }
              Text(name)
            }
          }
        } label: {
          HStack(spacing: 6) {
            Text(app.name.isEmpty ? "Select app..." : app.name)
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(app.name.isEmpty ? .secondary : .primary)
          }
        }
        .menuStyle(.borderlessButton)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider().padding(.leading, 12)

      // Effect picker row
      HStack {
        Text("Effect")
          .foregroundStyle(.secondary)
        Spacer()
        Picker("Effect", selection: $app.effect) {
          ForEach(Effect.allCases, id: \.self) { effect in
            Text(effect.label).tag(effect)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      if app.effect == .glow {
        Divider().padding(.leading, 12)

        HStack(spacing: 8) {
          if app.glowSettings.settingsMode == .advanced {
            Picker("Badge type", selection: $advancedTab) {
              ForEach(AdvancedTab.allCases, id: \.self) { tab in
                Text(tab.label).tag(tab)
              }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: advancedTab) {
              updatePreview()
            }
          }

          Spacer()

          Toggle(
            "By badge type",
            isOn: Binding(
              get: { app.glowSettings.settingsMode == .advanced },
              set: { app.glowSettings.settingsMode = $0 ? .advanced : .basic }
            )
          )
          .toggleStyle(.switch)
          .controlSize(.regular)
          .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        GlowAppearanceControls(
          appearance: app.glowSettings.settingsMode == .advanced
            && advancedTab == .nonNumeric
            ? $app.glowSettings.nonNumeric
            : $app.glowSettings.normal
        )
      }

      Spacer()
    }
    .padding(.horizontal, 12)
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .onHover { hovering in
      isHovering = hovering
      updatePreview()
    }
    .onChange(of: app) {
      if isHovering {
        updatePreview()
      }
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
        VStack(spacing: 16) {
          HStack(spacing: 18) {
            Text("ping").font(.custom("Chango", size: 48))
            if let bellImage = Bundle.module.url(
              forResource: "Bell", withExtension: "svg"
            )
            .flatMap(NSImage.init(contentsOf:))
            .map({
              $0.isTemplate = true
              return $0
            }) {
              Image(nsImage: bellImage)
                .resizable()
                .renderingMode(.template)
                .frame(width: 54, height: 54)
                .foregroundStyle(.primary)
            }
          }

          Text("Never miss a notification")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        // General section
        SettingsSection(title: "General") {
          HStack {
            Toggle(
              isOn: Binding(
                get: { state.launchOnStartup },
                set: { newValue in
                  do {
                    if newValue {
                      try SMAppService.mainApp.register()
                    } else {
                      try SMAppService.mainApp.unregister()
                    }
                    state.launchOnStartup = newValue
                  } catch {
                    print("Failed to update login item: \(error)")
                  }
                }
              )
            ) {
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

      // Floating Dock section
      SettingsSection(title: "Floating Dock") {
        // Position
        HStack {
          Text("Position")
            .foregroundStyle(.secondary)
          Spacer()
          Picker("Position", selection: $state.floatingDockSettings.position) {
            ForEach(DockPosition.allCases, id: \.self) { pos in
              Text(pos.label).tag(pos)
            }
          }
          .labelsHidden()
          .frame(width: 160)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Icon size
        HStack(spacing: 8) {
          Text("Icon size")
            .foregroundStyle(.secondary)
          Slider(value: $state.floatingDockSettings.iconSize, in: 16...64, step: 4)
          Text("\(Int(state.floatingDockSettings.iconSize))px")
            .monospacedDigit()
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Opacity
        HStack(spacing: 8) {
          Text("Opacity")
            .foregroundStyle(.secondary)
          Slider(value: $state.floatingDockSettings.opacity, in: 0.2...1.0, step: 0.05)
          Text("\(Int(state.floatingDockSettings.opacity * 100))%")
            .monospacedDigit()
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Margin
        HStack(spacing: 8) {
          Text("Margin")
            .foregroundStyle(.secondary)
          Slider(value: $state.floatingDockSettings.margin, in: 0...100, step: 5)
          Text("\(Int(state.floatingDockSettings.margin))px")
            .monospacedDigit()
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Padding
        HStack(spacing: 8) {
          Text("Padding")
            .foregroundStyle(.secondary)
          Slider(value: $state.floatingDockSettings.padding, in: 4...40, step: 2)
          Text("\(Int(state.floatingDockSettings.padding))px")
            .monospacedDigit()
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Background color
        HStack(spacing: 8) {
          Text("Background")
            .foregroundStyle(.secondary)
          Spacer()
          Picker("Background", selection: $state.floatingDockSettings.backgroundColor) {
            ForEach(GlowColor.allCases, id: \.self) { glowColor in
              HStack {
                Circle()
                  .fill(Color(nsColor: glowColor.nsColor))
                  .frame(width: 10, height: 10)
                Text(glowColor.rawValue)
              }
              .tag(glowColor)
            }
          }
          .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

        Divider().padding(.leading, 12)

        // Show app names
        HStack {
          Toggle(isOn: $state.floatingDockSettings.showAppNames) {
            Text("Show app names")
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
      }
      .padding(.horizontal, 20)
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
            state.apps.append(AppSettings(name: ""))
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
                appIcons: state.appIcons,
                onDelete: {
                  let id = app.id
                  withAnimation(.easeInOut(duration: 0.2)) {
                    state.apps.removeAll { $0.id == id }
                  }
                },
                onPreview: { config in
                  state.previewGlowConfig = config
                },
                onFloatingDockPreview: { show in
                  if show {
                    state.previewFloatingDockApps = [
                      FloatingDockItem(
                        appName: app.name.isEmpty ? "App" : app.name,
                        badge: "1",
                        icon: state.appIcons[app.name]
                      )
                    ]
                  } else {
                    state.previewFloatingDockApps = []
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
    .frame(maxWidth: 450, minHeight: 700, maxHeight: 700)
    .scenePadding()
  }
}
