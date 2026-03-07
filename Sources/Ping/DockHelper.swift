//
//  DockHelper.swift
//  Ping
//
//  Adapted from https://github.com/pock/pock/blob/9ee414fc35abe933057c87fab082bb9e67f5a34c/Pock/Private/PockDockHelper/PockDockHelper.m
//
//  Created by Tanner on 9/13/25.
//

import AppKit
@preconcurrency import ApplicationServices
import Cocoa
import Foundation

nonisolated(unsafe) private let kAXStatusLabelAttribute = "AXStatusLabel" as CFString

struct DockItem {
  let title: String
  let axElement: AXUIElement

  var appURL: URL? {
    var urlRef: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(
      self.axElement, kAXURLAttribute as CFString, &urlRef)
    guard error == .success else { return nil }
    return urlRef as? URL
  }

  func badgeCount() -> String? {
    var statusLabel: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(
      self.axElement,
      kAXStatusLabelAttribute,
      &statusLabel
    )

    guard error == .success else {
      return nil
    }

    let s = statusLabel as? String
    if let s = s, s.allSatisfy(\.isNumber) { return s } else { return "" }
  }

  static func list() -> [DockItem] {
    var result: [DockItem] = []

    let dockApps = NSRunningApplication.runningApplications(
      withBundleIdentifier: "com.apple.dock"
    )
    guard let dockApp = dockApps.first else { return result }

    let axDockApp = AXUIElementCreateApplication(dockApp.processIdentifier)

    guard
      let dockList = copyAXUIElement(
        from: axDockApp,
        role: kAXListRole as CFString,
        at: 0
      )
    else {
      return result
    }

    var children: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(
      dockList,
      kAXChildrenAttribute as CFString,
      &children
    )

    guard error == .success, let childrenArray = children else {
      return result
    }

    let elementsArray = childrenArray as! CFArray

    for i in 0..<CFArrayGetCount(elementsArray) {
      guard let element = CFArrayGetValueAtIndex(elementsArray, i) else { continue }
      let axElement = Unmanaged<AXUIElement>.fromOpaque(element)
        .takeUnretainedValue()

      // Only include actual application dock items
      var subrole: CFTypeRef?
      AXUIElementCopyAttributeValue(
        axElement,
        kAXSubroleAttribute as CFString,
        &subrole
      )
      guard let subroleString = subrole as? String,
        subroleString == "AXApplicationDockItem"
      else { continue }

      var title: CFTypeRef?
      let titleError = AXUIElementCopyAttributeValue(
        axElement,
        kAXTitleAttribute as CFString,
        &title
      )

      if titleError == .success, let titleString = title as? String {
        guard
          let axEl = copyAXUIElement(
            from: dockList,
            role: kAXDockItemRole as CFString,
            at: i
          )
        else { continue }
        result.append(
          DockItem(
            title: titleString,
            axElement: axEl
          )
        )
      }

    }
    return result
  }

  private static func copyAXUIElement(
    from container: AXUIElement,
    role: CFString?,
    at index: Int
  ) -> AXUIElement? {
    var children: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(
      container,
      kAXChildrenAttribute as CFString,
      &children
    )

    guard error == .success, let childrenArray = children else {
      return nil
    }

    let elementsArray = childrenArray as! CFArray
    var currentIndex = -1

    for i in 0..<CFArrayGetCount(elementsArray) {
      guard let element = CFArrayGetValueAtIndex(elementsArray, i) else { continue }
      let axElement = Unmanaged<AXUIElement>.fromOpaque(element)
        .takeUnretainedValue()

      if let role = role {
        var elementRole: CFTypeRef?
        let roleError = AXUIElementCopyAttributeValue(
          axElement,
          kAXRoleAttribute as CFString,
          &elementRole
        )

        if roleError == .success, let roleStr = elementRole {
          if CFStringCompare((roleStr as! CFString), role, [])
            == .compareEqualTo
          {
            currentIndex += 1
          }
        } else {
          continue
        }
      } else {
        currentIndex += 1
      }

      if currentIndex == index {
        return axElement
      }
    }

    return nil
  }

}
