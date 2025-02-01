//
//  AppDelegate.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Cocoa
import SwiftUI
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var keyboardManager: KeyboardManager?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var panelController: NSWindowController?
    private var panelManager: PanelManager?
    private var accessibilityWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if we're in privacy mode
        let isPrivacyMode = SettingsManager.shared.privacyMode
        
        if !isPrivacyMode {
            // Create a system-wide element and try to use it immediately to force the prompt
            let systemWide = AXUIElementCreateSystemWide()
            var value: AnyObject?
            _ = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &value)
            
            // Request permissions with prompt
            let options: [NSString: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
            let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            // Try to use accessibility features again to force the prompt
            _ = AXUIElementCopyAttributeValue(systemWide, kAXFocusedWindowAttribute as CFString, &value)
            
            // Try to initialize keyboard monitoring
            keyboardManager = KeyboardManager()
            
            // Show our window if permissions aren't granted yet
            if !accessEnabled && !AXIsProcessTrusted() {
                showAccessibilityPermissionWindow()
                return
            }
        } else {
            // In privacy mode, just initialize the keyboard manager
            keyboardManager = KeyboardManager()
        }
        
        initializeApp()
    }
    
    private func initializeApp() {
        // Initialize PanelManager
        panelManager = PanelManager.shared
        print("PanelManager initialized in AppDelegate")
        
        setupMenuBar()
        setupNotifications()
        
        // Open settings window if app is launched directly
        if NSApp.activationPolicy() == .regular {
            openSettings()
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        return SettingsManager.shared.privacyMode || AXIsProcessTrusted()
    }
    
    private func setupKeyboardManager() {
        // This function is no longer needed as we initialize directly in initializeApp
    }
    
    private func showAccessibilityPermissionWindow() {
        if accessibilityWindow == nil {
            let permissionView = AccessibilityPermissionView()
            accessibilityWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            accessibilityWindow?.title = "Accessibility Permissions"
            accessibilityWindow?.contentView = NSHostingView(rootView: permissionView)
            accessibilityWindow?.center()
            accessibilityWindow?.level = .floating
            accessibilityWindow?.isReleasedWhenClosed = false
            accessibilityWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            accessibilityWindow?.standardWindowButton(.zoomButton)?.isHidden = true
            accessibilityWindow?.delegate = self
        }
        
        accessibilityWindow?.makeKeyAndOrderFront(nil)
        accessibilityWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupMenuBar() {
        if SettingsManager.shared.showInMenuBar {
            createStatusItem()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MenuBarVisibilityChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let showInMenuBar = notification.object as? Bool {
                if showInMenuBar {
                    self?.createStatusItem()
                } else {
                    self?.statusItem = nil
                }
            }
        }
    }
    
    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyPane")
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "About KeyPane", action: #selector(openAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenSettings"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettings()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowRestartAlert"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showRestartAlert()
        }
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "KeyPane Settings"
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.center()
            settingsWindow?.level = .floating
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openAbout() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 220, height: 220),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About KeyPane"
            aboutWindow?.contentView = NSHostingView(rootView: aboutView)
            aboutWindow?.center()
            aboutWindow?.level = .floating
            aboutWindow?.titlebarAppearsTransparent = true
            aboutWindow?.isReleasedWhenClosed = false
            aboutWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            aboutWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        }
        
        aboutWindow?.makeKeyAndOrderFront(nil)
        aboutWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = "Restart Required"
        alert.informativeText = "KeyPane needs to restart to enable accessibility features. Would you like to restart now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")
        
        if let window = NSApplication.shared.mainWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    self.restartApp()
                }
            }
        } else {
            if alert.runModal() == .alertFirstButtonReturn {
                self.restartApp()
            }
        }
    }
    
    private func restartApp() {
        let bundlePath = Bundle.main.bundlePath
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: bundlePath),
                                         configuration: configuration) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == accessibilityWindow {
            NSApp.terminate(nil)
        }
    }
}
