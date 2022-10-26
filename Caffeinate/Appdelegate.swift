//
//  Appdelegate.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation
import AppKit
import IOKit.pwr_mgt


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var hasCoffee = false
    var hardMode = false
    var caffeinateTask :Progress?
    var noSleepAssertionID: IOPMAssertionID = 0
    var noSleepReturn: IOReturn?

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
        }
    }
    
    func reEnableSleep(_ hardMode: Bool) {
        if !hardMode {
            enableScreenSleep()
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
