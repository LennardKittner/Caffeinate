//
//  Appdelegate.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var hasCoffee = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateState(coffee: hasCoffee)
        statusBarItem?.button?.action = #selector(AppDelegate.caffeinat(_:))
    }
 
    @objc func caffeinat(_ sender: Any?) {
        hasCoffee.toggle()
        updateState(coffee: hasCoffee)
      }
    
    func updateState(coffee: Bool) {
        if coffee {
            statusBarItem?.button?.image = NSImage(
                systemSymbolName: "cup.and.saucer",
                accessibilityDescription: nil
              )
        } else {
            statusBarItem?.button?.image = NSImage(
                systemSymbolName: "cup.and.saucer.fill",
                accessibilityDescription: nil
              )
        }
    }
}
