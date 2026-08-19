//
//  Appdelegate.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation
import AppKit
import IOKit.pwr_mgt

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusBarItem: NSStatusItem?
    var hasCoffee = false
    var configHandler = ConfigHandler()
    // One IOPMAssertion per active caffeinate-style flag, keyed by assertion type.
    var activeAssertions: [String: IOPMAssertionID] = [:]

    // Menu items whose checkmarks we sync with the current state.
    private var menu: NSMenu!
    private var activeItem: NSMenuItem!
    private var displayItem: NSMenuItem!
    private var idleItem: NSMenuItem!
    private var diskItem: NSMenuItem!
    private var systemItem: NSMenuItem!
    private var loginItem: NSMenuItem!

    // Auto-off timer submenu items whose checkmarks track the config.
    private var timerParentItem: NSMenuItem!
    private var timerOffItem: NSMenuItem!
    private var timerCustomItem: NSMenuItem!
    private var timerPresetItems: [NSMenuItem] = []

    // When the auto-off timer is running, the moment it should turn itself off,
    // plus the 1s ticker that drives the countdown display and expiry.
    private var expiryDate: Date?
    private var tickTimer: Timer?

    // Duration presets shown in the "Auto-off after…" submenu.
    private static let timerPresets: [(title: String, seconds: TimeInterval)] = [
        ("15 minutes", 15 * 60),
        ("30 minutes", 30 * 60),
        ("1 hour", 60 * 60),
        ("2 hours", 2 * 60 * 60),
        ("4 hours", 4 * 60 * 60),
        ("8 hours", 8 * 60 * 60),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = buildMenu()
        // Left-click toggles active; right-click opens the menu. We deliberately
        // don't assign statusBarItem.menu, otherwise any click would open it.
        statusBarItem?.button?.action = #selector(statusItemClicked(_:))
        statusBarItem?.button?.target = self
        statusBarItem?.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusButton()
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            // Temporarily attach the menu so the status item pops it up, then
            // detach so the next left-click fires the action again.
            statusBarItem?.menu = menu
            statusBarItem?.button?.performClick(nil)
            statusBarItem?.menu = nil
        } else {
            toggleActive()
        }
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false // we manage enabled/checkmark state ourselves

        activeItem = addItem(to: menu, title: "Active", action: #selector(toggleActive))

        menu.addItem(.separator())

        menu.addItem(buildTimerSubmenu())

        menu.addItem(.separator())

        let header = NSMenuItem(title: "Keep Awake", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        displayItem = addFlagItem(to: menu, title: "Prevent display sleep", action: #selector(toggleDisplay))
        idleItem = addFlagItem(to: menu, title: "Prevent system idle sleep", action: #selector(toggleIdle))
        diskItem = addFlagItem(to: menu, title: "Prevent disk idle sleep", action: #selector(toggleDisk))
        systemItem = addFlagItem(to: menu, title: "Prevent system sleep (on AC power)", action: #selector(toggleSystem))

        menu.addItem(.separator())

        loginItem = addItem(to: menu, title: "Start at login", action: #selector(toggleLogin))

        menu.addItem(.separator())

        _ = addItem(to: menu, title: "About Caffeinate", action: #selector(showAbout))
        let quit = addItem(to: menu, title: "Quit Caffeinate", action: #selector(quit))
        quit.keyEquivalent = "q"

        return menu
    }

    @discardableResult
    private func addItem(to menu: NSMenu, title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    private func addFlagItem(to menu: NSMenu, title: String, action: Selector) -> NSMenuItem {
        let item = addItem(to: menu, title: title, action: action)
        item.indentationLevel = 1
        return item
    }

    // Builds the "Auto-off after…" parent item and its submenu of durations.
    private func buildTimerSubmenu() -> NSMenuItem {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        timerOffItem = NSMenuItem(title: "Off", action: #selector(disableTimer), keyEquivalent: "")
        timerOffItem.target = self
        submenu.addItem(timerOffItem)

        submenu.addItem(.separator())

        for preset in Self.timerPresets {
            let item = NSMenuItem(title: preset.title, action: #selector(selectTimerDuration(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.seconds
            submenu.addItem(item)
            timerPresetItems.append(item)
        }

        submenu.addItem(.separator())

        timerCustomItem = NSMenuItem(title: "Custom…", action: #selector(customTimer), keyEquivalent: "")
        timerCustomItem.target = self
        submenu.addItem(timerCustomItem)

        let parent = NSMenuItem(title: "Auto-off after…", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        timerParentItem = parent
        return parent
    }

    // Human-readable duration, reusing a preset's wording when one matches.
    private func durationLabel(_ seconds: TimeInterval) -> String {
        if let preset = Self.timerPresets.first(where: { $0.seconds == seconds }) {
            return preset.title
        }
        let total = max(0, Int(seconds))
        let h = total / 3600, m = (total % 3600) / 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) hour\(h == 1 ? "" : "s")") }
        if m > 0 { parts.append("\(m) minute\(m == 1 ? "" : "s")") }
        if parts.isEmpty { parts.append("\(total) second\(total == 1 ? "" : "s")") }
        return parts.joined(separator: " ")
    }

    // Sync checkmarks/enabled state whenever the menu is about to open.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let conf = configHandler.conf
        activeItem.state = hasCoffee ? .on : .off
        updateActiveItemTitle()
        displayItem.state = conf.preventDisplaySleep ? .on : .off
        idleItem.state = conf.preventIdleSleep ? .on : .off
        diskItem.state = conf.preventDiskIdle ? .on : .off
        systemItem.state = conf.preventSystemSleep ? .on : .off
        loginItem.state = conf.atLogin ? .on : .off
        loginItem.isEnabled = configHandler.macOS13

        // Auto-off submenu: surface the current selection on the parent row so
        // it's readable without opening the submenu, and check the matching
        // preset, or Custom when the duration isn't a preset, or Off when off.
        timerParentItem.title = conf.timerEnabled ? "Auto-off after \(durationLabel(conf.timerDuration))" : "Auto-off after…"
        timerOffItem.state = conf.timerEnabled ? .off : .on
        var matchedPreset = false
        for item in timerPresetItems {
            let match = conf.timerEnabled && (item.representedObject as? TimeInterval) == conf.timerDuration
            item.state = match ? .on : .off
            if match { matchedPreset = true }
        }
        timerCustomItem.state = (conf.timerEnabled && !matchedPreset) ? .on : .off
    }

    // MARK: - Actions

    @objc private func toggleActive() {
        setActive(!hasCoffee)
    }

    private func setActive(_ active: Bool) {
        if active {
            hasCoffee = createAssertions(reason: "Caffeinate")
            if hasCoffee { startAutoOffIfNeeded() }
        } else {
            _ = releaseAssertions()
            hasCoffee = false
            stopAutoOff()
        }
        updateStatusButton()
    }

    // Flag toggles update the persisted config and re-apply live when active.
    @objc private func toggleDisplay() { flip { $0.preventDisplaySleep.toggle() } }
    @objc private func toggleIdle()    { flip { $0.preventIdleSleep.toggle() } }
    @objc private func toggleDisk()    { flip { $0.preventDiskIdle.toggle() } }
    @objc private func toggleSystem()  { flip { $0.preventSystemSleep.toggle() } }

    private func flip(_ change: (ConfigData) -> Void) {
        configHandler.mutateConfig(change)
        if hasCoffee {
            // Re-apply so the change takes effect immediately. If nothing is
            // selected anymore, we end up inactive.
            hasCoffee = createAssertions(reason: "Caffeinate")
            if !hasCoffee { stopAutoOff() }
            updateStatusButton()
        }
    }

    // MARK: - Auto-off timer

    // Picking a preset/custom duration enables the timer; if already active,
    // (re)start the countdown from now.
    @objc private func selectTimerDuration(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        configHandler.mutateConfig {
            $0.timerEnabled = true
            $0.timerDuration = seconds
        }
        if hasCoffee { startAutoOffIfNeeded() }
        updateStatusButton()
    }

    @objc private func disableTimer() {
        configHandler.mutateConfig { $0.timerEnabled = false }
        stopAutoOff()
        updateStatusButton()
    }

    // Prompts for an arbitrary duration in minutes.
    @objc private func customTimer() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Custom Auto-off Timer"
        alert.informativeText = "Turn Caffeinate off automatically after this many minutes:"
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.stringValue = String(max(1, Int((configHandler.conf.timerDuration / 60).rounded())))
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.allowsFloats = false
        field.formatter = formatter
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard let minutes = Int(field.stringValue), minutes > 0 else { return }
        configHandler.mutateConfig {
            $0.timerEnabled = true
            $0.timerDuration = TimeInterval(minutes * 60)
        }
        if hasCoffee { startAutoOffIfNeeded() }
        updateStatusButton()
    }

    // Starts (or restarts) the countdown when the timer is enabled. No-op
    // otherwise, so activation without a timer just stays on indefinitely.
    private func startAutoOffIfNeeded() {
        stopAutoOff()
        guard configHandler.conf.timerEnabled else { return }
        expiryDate = Date().addingTimeInterval(configHandler.conf.timerDuration)
        // Add in .common mode so the countdown keeps ticking while the menu is
        // open (menu tracking runs the run loop in a different mode).
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func stopAutoOff() {
        tickTimer?.invalidate()
        tickTimer = nil
        expiryDate = nil
    }

    @objc private func tick() {
        guard let expiry = expiryDate else { return }
        if expiry.timeIntervalSinceNow <= 0 {
            setActive(false)
        } else {
            updateStatusButton()
            updateActiveItemTitle()
        }
    }

    // Compact "H:MM" / "M:SS" form for the menu-bar button.
    private func formatCompact(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d", h, m) : String(format: "%d:%02d", m, s)
    }

    // Full "H:MM:SS" / "M:SS" form for the dropdown row and tooltip.
    private func formatFull(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    private func updateActiveItemTitle() {
        if hasCoffee, let expiry = expiryDate {
            activeItem.title = "Active — \(formatFull(expiry.timeIntervalSinceNow)) left"
        } else {
            activeItem.title = "Active"
        }
    }

    @objc private func toggleLogin() {
        let desired = !configHandler.conf.atLogin
        switch configHandler.setAtLogin(desired) {
        case .ok, .unsupported:
            break
        case .requiresApproval:
            showLoginAlert("Caffeinate needs your approval to start at login. Enable it under System Settings → General → Login Items.")
        case .failed(let error):
            showLoginAlert("Couldn't update the login item: \(error.localizedDescription)")
        }
    }

    private func showLoginAlert(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Start at Login"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        configHandler.quitApp()
    }

    private func updateStatusButton() {
        guard let button = statusBarItem?.button else { return }
        let symbol = hasCoffee ? "cup.and.saucer.fill" : "cup.and.saucer"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        if hasCoffee, let expiry = expiryDate {
            let remaining = expiry.timeIntervalSinceNow
            button.title = " " + formatCompact(remaining)
            button.imagePosition = .imageLeading
            button.toolTip = "Caffeinate is active — \(formatFull(remaining)) remaining"
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
            button.toolTip = hasCoffee ? "Caffeinate is active" : "Caffeinate is not active"
        }
    }

    // MARK: - Power assertions (mirrors caffeinate(8))

    // The enabled flags map onto IOKit power-management assertion types.
    private func selectedAssertionTypes() -> [String] {
        let conf = configHandler.conf
        var types: [String] = []
        if conf.preventDisplaySleep { types.append(kIOPMAssertionTypePreventUserIdleDisplaySleep as String) } // -d
        if conf.preventIdleSleep { types.append(kIOPMAssertionTypePreventUserIdleSystemSleep as String) }     // -i
        if conf.preventDiskIdle { types.append(kIOPMAssertPreventDiskIdle as String) }                        // -m
        if conf.preventSystemSleep { types.append(kIOPMAssertionTypePreventSystemSleep as String) }           // -s
        return types
    }

    // Creates one assertion per selected flag. Returns true if at least one is
    // held. Any previously held assertions are released first.
    @discardableResult
    func createAssertions(reason: String = "Unknown reason") -> Bool {
        _ = releaseAssertions()
        for type in selectedAssertionTypes() {
            var assertionID: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(type as CFString,
                                                     IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                     reason as CFString,
                                                     &assertionID)
            if result == kIOReturnSuccess {
                activeAssertions[type] = assertionID
            }
        }
        return !activeAssertions.isEmpty
    }

    @discardableResult
    func releaseAssertions() -> Bool {
        guard !activeAssertions.isEmpty else { return false }
        for (_, assertionID) in activeAssertions {
            _ = IOPMAssertionRelease(assertionID)
        }
        activeAssertions.removeAll()
        return true
    }
}
