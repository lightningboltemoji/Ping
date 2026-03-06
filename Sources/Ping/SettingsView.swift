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
    let appIcons: [String: NSImage]
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Identity row
            HStack(spacing: 8) {
                if let icon = appIcons[app.name] {
                    Image(nsImage: icon).resizable()
                        .frame(width: 22, height: 22).padding(1)
                } else {
                    Circle()
                        .fill(Color(nsColor: AppState.resolvedColor(for: app, badge: "")))
                        .frame(width: 16, height: 16)
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
                Slider(value: $app.size, in: 0.25...1.0, step: 0.05)
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
                Slider(value: $app.opacity, in: 0.4...1.0, step: 0.05)
                Text("\(Int(app.opacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().padding(.leading, 12)

            HStack(spacing: 8) {
                Text("Colors")
                    .foregroundStyle(.secondary)

                Spacer()

                if app.colorOption == .basic {
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
                    .frame(width: 140)
                }

                Spacer()

                Picker("Color option", selection: $app.colorOption) {
                    ForEach(ColorOptions.allCases, id: \.self) { co in
                        Text(co.rawValue.capitalized).tag(co)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if app.colorOption == .advanced {
                HStack(spacing: 8) {
                    Picker("Numeric", selection: $app.color) {
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
                    .labelsVisibility(app.colorOption == .advanced ? .visible : .hidden)
                    .frame(width: 140)

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
                    .frame(width: 180)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
            onHover(hovering)
        }
        .onChange(of: app) {
            if isHovering {
                onHover(true)
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
                                appIcons: state.appIcons,
                                onDelete: {
                                    let id = app.id
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        state.apps.removeAll { $0.id == id }
                                    }
                                },
                                onHover: { hovering in
                                    if hovering {
                                        state.previewGlowConfig = AppState.resolvedConfig(
                                            for: app, badge: "")
                                    } else {
                                        state.previewGlowConfig = nil
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
