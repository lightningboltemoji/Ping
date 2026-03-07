//
//  PingApp.swift
//  Ping
//
//  Created by Tanner on 9/13/25.
//

import ServiceManagement
import SwiftUI

@main
@available(macOS 26, *)
struct PingApp: App {

  private let state: AppState
  private let dockPoller: DockPoller
  private let glowController: GlowController
  private let settingsAutoSaver: SettingsAutoSaver

  init() {
    let state = AppState()
    if let saved = SettingsPersistence.load() {
      state.refreshInterval = saved.refreshInterval
      state.apps = saved.apps
    }
    state.launchOnStartup = SMAppService.mainApp.status == .enabled
    self.state = state
    self.dockPoller = DockPoller(state: state)
    self.glowController = GlowController(state: state, screen: NSScreen.main)
    self.settingsAutoSaver = SettingsAutoSaver(state: state)
  }

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup("Accessibility") {
      AccessibilityView()
    }
    .windowLevel(.floating)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)

    MenuBarExtra("Ping", systemImage: "bell.fill") {
      Text("ping").font(.custom("Chango", size: 13))
      Divider()
      SettingsLink {
        Text("Settings")
      }
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q", modifiers: .command)
    }

    Settings {
      SettingsView().onAppear {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: {
          $0.identifier?.rawValue.contains("Settings") ?? false
        }) {
          window.titlebarAppearsTransparent = true
          window.titleVisibility = .hidden
          window.styleMask.insert(.fullSizeContentView)
        }
      }
      .onDisappear {
        NSApp.setActivationPolicy(.accessory)
      }
    }
    .environment(state)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
  }
}
