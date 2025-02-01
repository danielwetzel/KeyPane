//
//  PanelManager.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Cocoa
import SwiftUI

public class PanelManager {
    public static let shared = PanelManager()
    private var panel: NSPanel?
    private var initialMouseLocation: NSPoint?
    private var initialWindowLocation: NSPoint?
    private var contentView: BlurPaneView?
    private var globalMouseMonitor: Any?
    
    private var settings: SettingsManager {
        SettingsManager.shared
    }
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowPanel),
            name: NSNotification.Name("ShowPanel"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHidePanel),
            name: NSNotification.Name("HidePanel"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInsertCharacter),
            name: NSNotification.Name("InsertCharacter"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePanelSizeChanged),
            name: NSNotification.Name("PanelSizeChanged"),
            object: nil
        )
    }
    
    private func setupMouseMonitor() {
        removeMouseMonitor()
        
        // Only setup if click-to-close is enabled
        guard settings.clickToClose else { return }
        
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel else { return }
            
            // Get the click location in screen coordinates
            let clickLocation = event.locationInWindow
            
            // Convert panel frame to screen coordinates
            let panelFrame = panel.frame
            
            // If click is outside panel frame, hide the panel
            if !NSPointInRect(clickLocation, panelFrame) {
                self.hidePanel()
            }
        }
    }
    
    private func removeMouseMonitor() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }
    
    private func setupPanel() {
        contentView = BlurPaneView()
        let hostingController = NSHostingController(rootView: contentView!)
        
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel?.contentViewController = hostingController
        panel?.level = .popUpMenu
        panel?.isOpaque = false
        panel?.backgroundColor = .clear
        panel?.hasShadow = true
        panel?.isMovable = true
        panel?.isMovableByWindowBackground = true
        panel?.ignoresMouseEvents = false
        panel?.acceptsMouseMovedEvents = true
        panel?.becomesKeyOnlyIfNeeded = true
        
        // Set initial size and position
        let baseWidth: CGFloat = 900
        let baseHeight: CGFloat = 320
        let scaledSize = NSSize(
            width: baseWidth * settings.panelSize,
            height: baseHeight * settings.panelSize
        )
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newOrigin = NSPoint(
                x: screenRect.midX - scaledSize.width / 2,
                y: screenRect.midY - scaledSize.height / 2
            )
            panel?.setFrame(NSRect(origin: newOrigin, size: scaledSize), display: true)
        }
    }
    
    private func showPanel() {
        if panel == nil {
            setupPanel()
        }
        
        setupMouseMonitor()
        panel?.orderFront(nil)
    }
    
    private func hidePanel() {
        removeMouseMonitor()
        panel?.orderOut(nil)
        
        // Notify that the panel is hidden
        NotificationCenter.default.post(name: NSNotification.Name("PanelDidHide"), object: nil)
    }
    
    @objc private func handleShowPanel() {
        showPanel()
    }
    
    @objc private func handleHidePanel() {
        hidePanel()
    }
    
    @objc private func handleInsertCharacter(_ notification: Notification) {
        guard settings.enableMouseClicks,
              let character = notification.object as? String else { return }
        
        // Get the frontmost application and its key window
        if let app = NSWorkspace.shared.frontmostApplication {
            // Create and post a key event
            let src = CGEventSource(stateID: .hidSystemState)
            
            // Convert character to UniChar array
            let chars = Array(character.utf16)
            chars.withUnsafeBufferPointer { buffer in
                let event = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true)
                event?.flags = .maskNonCoalesced
                event?.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: buffer.baseAddress)
                event?.post(tap: .cgAnnotatedSessionEventTap)
                
                // Key up event
                let upEvent = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false)
                upEvent?.flags = .maskNonCoalesced
                upEvent?.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: buffer.baseAddress)
                upEvent?.post(tap: .cgAnnotatedSessionEventTap)
            }
        }
    }
    
    @objc private func handlePanelSizeChanged(_ notification: Notification) {
        updatePanelSize()
    }
    
    private func updatePanelSize() {
        guard let panel = panel else { return }
        
        // Calculate new size
        let baseWidth: CGFloat = 900
        let baseHeight: CGFloat = 100
        let newSize = NSSize(
            width: baseWidth * settings.panelSize,
            height: baseHeight * settings.panelSize
        )
        
        // Calculate center position on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            
            // Calculate center position, accounting for menubar height
            let newOrigin = NSPoint(
                x: (screenRect.width - newSize.width) / 2,
                y: (screenRect.height - newSize.height) / 3
            )
            
            // Update size and position
            panel.setFrame(NSRect(origin: newOrigin, size: newSize), display: true, animate: false)
        }
        
        // Force content view update
        contentView = BlurPaneView()
        panel.contentViewController = NSHostingController(rootView: contentView!)
    }
    
    deinit {
        removeMouseMonitor()
        handleHidePanel()
        NotificationCenter.default.removeObserver(self)
    }
}
