//
//  Appdelegate.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation
import AppKit
import IOKit.pwr_mgt
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var hasCoffee = false
    var hardMode = false // alwasys false (for now)
    var configHandler = ConfigHandler()
    var caffeinateTask :Progress?
    var noSleepAssertionID: IOPMAssertionID = 0
    var noSleepReturn: IOReturn?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateState(coffee: hasCoffee)
        statusBarItem?.button?.action = #selector(AppDelegate.statusItemClicked(_:))
        statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
     
    @objc func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            var toolbar = Toolbar(tabs: ["About", "Settings"]).environmentObject(configHandler)
            TabView()
                .environmentObject(configHandler)
                .openNewWindowWithToolbar(title: "Caffeinate", rect: NSRect(x: 0, y: 0, width: 450, height: 150), style: [.closable, .titled],identifier: "Settings", toolbar: toolbar)
        } else {
            hasCoffee.toggle()
            updateState(coffee: hasCoffee)
        }
      }
    
    func updateState(coffee: Bool) {
        if coffee {
            preventSleep(hardMode)
            statusBarItem?.button?.image = NSImage(
                systemSymbolName: "cup.and.saucer.fill",
                accessibilityDescription: nil
              )
        } else {
            reEnableSleep(hardMode)
            statusBarItem?.button?.image = NSImage(
                systemSymbolName: "cup.and.saucer",
                accessibilityDescription: nil
              )
        }
    }
        
    func preventSleep(_ hardMode: Bool) {
        if !hardMode {
            disableScreenSleep(reason: "Caffeinate")
        } else {
            // This requires root privileges.
            // TODO: figure out how to get privileges.
            // https://github.com/trilemma-dev/SwiftAuthorizationSample/tree/main
            DispatchQueue.global(qos: .background).async {
                var errorDict: NSDictionary? = nil
                NSAppleScript(source: "do shell script \"sudo pmset disablesleep 1\" with administrator privileges")!.executeAndReturnError(&errorDict)
            }
        }
    }
    
    func reEnableSleep(_ hardMode: Bool) {
        if !hardMode {
            enableScreenSleep()
        } else {
            // This requires root privileges.
            // TODO: figure out how to get privileges.
            // https://github.com/trilemma-dev/SwiftAuthorizationSample/tree/main
            DispatchQueue.global(qos: .background).async {
                var errorDict: NSDictionary? = nil
                NSAppleScript(source: "do shell script \"sudo pmset disablesleep 0\" with administrator privileges")!.executeAndReturnError(&errorDict)
            }
        }
    }
  
    // https://stackoverflow.com/questions/37601453/using-swift-to-disable-sleep-screen-saver-for-osx
    
    func disableScreenSleep(reason: String = "Unknown reason") -> Bool? {
        guard noSleepReturn == nil else { return nil }
        noSleepReturn = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                reason as CFString,
                                                &noSleepAssertionID)
        return noSleepReturn == kIOReturnSuccess
    }

    func enableScreenSleep() -> Bool {
        if noSleepReturn != nil {
            _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
            noSleepReturn = nil
            return true
        }
        return false
    }
}
