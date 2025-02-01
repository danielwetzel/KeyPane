//
//  KeyboardManager.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Cocoa

public class KeyboardManager {
    private var eventTap: CFMachPort?
    private var eventMonitor: (local: Any?, global: Any?)?
    private var lastOptionTapTime: CFAbsoluteTime = 0
    private var isOptionKeyPressed = false
    private var optionKeyHoldTimer: Timer?
    private var isPanelVisible = false
    private var currentModifiers = Set<String>()
    private var isPrivacyMode: Bool
    
    // Cache notification names for better performance
    private let keyPressedNotification = NSNotification.Name("KeyPressed")
    private let keyReleasedNotification = NSNotification.Name("KeyReleased")
    private let showPanelNotification = NSNotification.Name("ShowPanel")
    private let hidePanelNotification = NSNotification.Name("HidePanel")
    
    // Cache UserDefaults keys
    private let defaults = UserDefaults.standard
    private let toggleModeKey = "toggleMode"
    private let keepPanelOpenKey = "keepPanelOpen"
    
    // Use computed properties for settings to always get latest values
    private var toggleMode: Bool { defaults.bool(forKey: toggleModeKey) }
    private var keepPanelOpen: Bool { defaults.bool(forKey: keepPanelOpenKey) }
    
    private var keyCodeMappings: [String: String] = [:]
    
    public init() {
        self.isPrivacyMode = SettingsManager.shared.privacyMode
        self.eventMonitor = (nil, nil)
        
        // Listen for panel hide notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePanelDidHide),
            name: NSNotification.Name("PanelDidHide"),
            object: nil
        )
        
        // Listen for privacy mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePrivacyModeChanged),
            name: NSNotification.Name("PrivacyModeChanged"),
            object: nil
        )
        
        loadKeyCodeMappings()
        startMonitoring()
    }
    
    @objc private func handlePrivacyModeChanged(_ notification: Notification) {
        if let newMode = notification.object as? Bool {
            let oldMode = isPrivacyMode
            isPrivacyMode = newMode
            
            // If switching from privacy mode to default mode, we need to restart the app
            if oldMode == true && newMode == false {
                DispatchQueue.main.async {
                    // Post a notification to show an alert before restarting
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowRestartAlert"),
                        object: nil
                    )
                }
            } else {
                // For other cases, just switch the monitoring mode
                stopMonitoring()
                startMonitoring()
            }
        }
    }
    
    func startMonitoring() {
        if isPrivacyMode {
            startNSEventMonitoring()
        } else {
            startAccessibilityMonitoring()
        }
    }
    
    private func startNSEventMonitoring() {
        // Create a local monitor for key events
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            self.handleNSEvent(event)
            return event
        }
        
        // Create a global monitor for key events when app is not active
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            self.handleNSEvent(event)
        }
        
        eventMonitor = (local: localMonitor, global: globalMonitor)
    }
    
    private func startAccessibilityMonitoring() {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | 
                       (1 << CGEventType.keyDown.rawValue) | 
                       (1 << CGEventType.keyUp.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, userInfo) in
            let keyboardManager = Unmanaged<KeyboardManager>.fromOpaque(userInfo!).takeUnretainedValue()
            
            switch type {
            case .flagsChanged:
                keyboardManager.handleFlagsChanged(event)
            case .keyDown, .keyUp:
                if keyboardManager.isPanelVisible {
                    keyboardManager.handleKeyEvent(type, event)
                }
            default:
                break
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: context
        ) else {
            print("Failed to create event tap. Ensure accessibility permissions are granted.")
            return
        }
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleNSEvent(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            let flags = event.modifierFlags
            let wasOptionPressed = isOptionKeyPressed
            isOptionKeyPressed = flags.contains(.option)
            
            // Handle modifier keys
            let newModifiers = Set([
                flags.contains(.shift) ? "⇧" : nil,
                flags.contains(.control) ? "control" : nil,
                flags.contains(.option) ? "option" : nil,
                flags.contains(.command) ? "command" : nil
            ].compactMap { $0 })
            
            if newModifiers != currentModifiers {
                let addedModifiers = newModifiers.subtracting(currentModifiers)
                let removedModifiers = currentModifiers.subtracting(newModifiers)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for key in addedModifiers {
                        NotificationCenter.default.post(name: self.keyPressedNotification, object: key)
                    }
                    for key in removedModifiers {
                        NotificationCenter.default.post(name: self.keyReleasedNotification, object: key)
                    }
                }
                
                currentModifiers = newModifiers
            }
            
            // Handle option key state changes
            if !wasOptionPressed && isOptionKeyPressed {
                handleOptionKeyPress()
            } else if wasOptionPressed && !isOptionKeyPressed {
                handleOptionKeyRelease()
            }
            
        case .keyDown, .keyUp:
            if isPanelVisible {
                let keyName = keyCodeToString(Int64(event.keyCode)).lowercased()
                
                if event.type == .keyDown && event.keyCode == 53 {  // ESC key
                    hidePanel()
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    NotificationCenter.default.post(
                        name: event.type == .keyDown ? self.keyPressedNotification : self.keyReleasedNotification,
                        object: keyName
                    )
                }
                
                if event.type == .keyDown && !keepPanelOpen {
                    hidePanel()
                }
            }
            
        default:
            break
        }
    }
    
    private func stopMonitoring() {
        if let monitors = eventMonitor {
            if let local = monitors.local {
                NSEvent.removeMonitor(local)
            }
            if let global = monitors.global {
                NSEvent.removeMonitor(global)
            }
        }
        eventMonitor = nil
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
        eventTap = nil
    }
    
    private func handleFlagsChanged(_ event: CGEvent) {
        let flags = event.flags
        let wasOptionPressed = isOptionKeyPressed
        isOptionKeyPressed = flags.contains(.maskAlternate)
        
        // Handle modifier keys
        let newModifiers = Set([
            flags.contains(.maskShift) ? "⇧" : nil,
            flags.contains(.maskControl) ? "control" : nil,
            flags.contains(.maskAlternate) ? "option" : nil,
            flags.contains(.maskCommand) ? "command" : nil
        ].compactMap { $0 })
        
        // Only process if modifiers changed
        if newModifiers != currentModifiers {
            let addedModifiers = newModifiers.subtracting(currentModifiers)
            let removedModifiers = currentModifiers.subtracting(newModifiers)
            
            if !addedModifiers.isEmpty || !removedModifiers.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for key in addedModifiers {
                        NotificationCenter.default.post(name: self.keyPressedNotification, object: key)
                    }
                    for key in removedModifiers {
                        NotificationCenter.default.post(name: self.keyReleasedNotification, object: key)
                    }
                }
            }
            
            currentModifiers = newModifiers
        }
        
        // Handle option key state changes
        if !wasOptionPressed && isOptionKeyPressed {
            handleOptionKeyPress()
        } else if wasOptionPressed && !isOptionKeyPressed {
            handleOptionKeyRelease()
        }
    }
    
    private func handleOptionKeyPress() {
        let now = CFAbsoluteTimeGetCurrent()
        let timeDiff = now - lastOptionTapTime
        
        if timeDiff < 0.4 {
            if toggleMode {
                togglePanel()
            } else {
                optionKeyHoldTimer?.invalidate()
                optionKeyHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                    guard let self = self, self.isOptionKeyPressed else { return }
                    self.showPanel()
                }
            }
        }
        
        lastOptionTapTime = now
    }
    
    private func handleOptionKeyRelease() {
        optionKeyHoldTimer?.invalidate()
        optionKeyHoldTimer = nil
        
        if !toggleMode && isPanelVisible {
            hidePanel()
        }
    }
    
    private func handleKeyEvent(_ type: CGEventType, _ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Handle ESC key in toggle mode
        if toggleMode && type == .keyDown && keyCode == 53 {
            hidePanel()
            return
        }
        
        let keyName = keyCodeToString(keyCode).lowercased()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(
                name: type == .keyDown ? self.keyPressedNotification : self.keyReleasedNotification,
                object: keyName
            )
            
            if type == .keyDown && !self.keepPanelOpen {
                self.hidePanel()
            }
        }
    }
    
    private func showPanel() {
        isPanelVisible = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(name: self.showPanelNotification, object: nil)
        }
    }
    
    private func hidePanel() {
        isPanelVisible = false
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(name: self.hidePanelNotification, object: nil)
        }
    }
    
    private func togglePanel() {
        isPanelVisible.toggle()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(
                name: self.isPanelVisible ? self.showPanelNotification : self.hidePanelNotification,
                object: nil
            )
        }
    }
    
    private func loadKeyCodeMappings() {
        guard let url = Bundle.main.url(forResource: "keyCodeMappings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let mappings = try? JSONDecoder().decode([String: [String: String]].self, from: data),
              let qwertzMappings = mappings["qwertz"] else {
            print("Failed to load key code mappings")
            return
        }
        keyCodeMappings = qwertzMappings
    }
    
    private func keyCodeToString(_ keyCode: Int64) -> String {
        let keyCodeString = String(keyCode)
        return keyCodeMappings[keyCodeString] ?? "Key(\(keyCode))"
    }
    
    deinit {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handlePanelDidHide() {
        isPanelVisible = false
    }
}

// Helper struct to manage context
fileprivate struct CGEventTapContext {
    var eventTapOwner: KeyboardManager
}
