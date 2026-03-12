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
  private let lineController: LineController
  private let floatingDockController: FloatingDockController
  private let settingsAutoSaver: SettingsAutoSaver

  init() {
    let state = AppState()
    if let saved = SettingsPersistence.load() {
      state.refreshInterval = saved.refreshInterval
      state.apps = saved.apps
      state.lineSettings = saved.lineSettings
      state.floatingDockSettings = saved.floatingDockSettings
    }
    state.launchOnStartup = SMAppService.mainApp.status == .enabled
    self.state = state
    self.dockPoller = DockPoller(state: state)
    self.glowController = GlowController(state: state, screen: NSScreen.main)
    self.lineController = LineController(state: state, screen: NSScreen.main)
    self.floatingDockController = FloatingDockController(state: state)
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

    MenuBarExtra {
      Text("ping").font(.custom("Chango", size: 13))
      Divider()
      AcknowledgeMenuContent(state: state)
      Divider()
      SnoozeMenuContent(state: state)
      Divider()
      SettingsLink {
        Text("Settings")
      }
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q", modifiers: .command)
    } label: {
      let image: NSImage = {
        guard
          let url = Bundle.module.url(forResource: "Bell", withExtension: "svg"),
          let img = NSImage(contentsOf: url)
        else {
          return NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Ping")!
        }
        img.isTemplate = true
        img.size = NSSize(width: 18, height: 18)
        return img
      }()
      Image(nsImage: image)
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

@available(macOS 26, *)
struct AcknowledgeMenuContent: View {
  let state: AppState

  var body: some View {
    Button("Acknowledge") {
      state.acknowledge()
    }
    .disabled(state.currentBadges.isEmpty)
    if state.hasAcknowledgedApps {
      let names = state.acknowledgedBadges.keys.sorted().joined(separator: ", ")
      Text("Suppressed: \(names)")
    }
  }
}

@available(macOS 26, *)
struct SnoozeMenuContent: View {
  let state: AppState
  @State private var now = Date()

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let durations: [Int] = [1, 5, 10, 15, 20, 30, 45, 60]

  var body: some View {
    if state.isSnoozed, let snoozedUntil = state.snoozedUntil {
      let remaining = max(0, Int(snoozedUntil.timeIntervalSince(now)))
      let minutes = remaining / 60
      let seconds = remaining % 60
      Button("End snooze early (\(String(format: "%02d:%02d", minutes, seconds)))") {
        state.snoozedUntil = nil
      }
      .onReceive(timer) { tick in
        now = tick
        if !state.isSnoozed {
          state.snoozedUntil = nil
        }
      }
    } else {
      Menu("Snooze") {
        ForEach(durations, id: \.self) { mins in
          Button("\(mins) minute\(mins == 1 ? "" : "s")") {
            state.snoozedUntil = Date().addingTimeInterval(Double(mins) * 60)
          }
        }
      }
    }
  }
}
