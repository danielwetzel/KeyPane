//
//  BlurPaneView.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import SwiftUI

struct KeyView: View {
    let key: KeyModel
    let isPressed: Bool
    let width: CGFloat
    let mode: Int // 0: normal, 1: opt, 2: opt+shift
    @Environment(\.pressedKeys) var pressedKeys
    
    private var optColor: Color {
        SettingsManager.shared.colorPreset.optColor
    }
    
    private var optShiftColor: Color {
        SettingsManager.shared.colorPreset.optShiftColor
    }
    
    private var keyIcon: String? {
        switch key.label {
        case "command": return "command"
        case "option": return "option"
        case "⇧": return "shift"
        case "control": return "control"
        case "fn": return "function"
        case "⌫": return "delete.left"
        case "⏎": return "return"
        case "⇥": return "arrow.right.to.line"
        case "⇪": return "capslock"
        default: return nil
        }
    }
    
    private var displayedLabel: String {
        if let iconName = keyIcon {
            return ""
        }
        
        // Handle shift key independently of option modes
        let baseLabel = if pressedKeys.contains("⇧") || pressedKeys.contains("⇪") {
            key.shift ?? key.label.uppercased()
        } else {
            key.label
        }
        
        // Only modify the label for option modes if we're not showing all special chars
        if !SettingsManager.shared.showAllSpecialChars {
            if mode == 2 {
                return key.optShift ?? key.opt ?? baseLabel
            } else if mode == 1 {
                return key.opt ?? baseLabel
            }
        }
        
        return baseLabel
    }
    
    var body: some View {
        VStack(spacing: 2 * SettingsManager.shared.panelSize) {
            if let iconName = keyIcon {
                Image(systemName: iconName)
                    .font(.system(size: 16 * SettingsManager.shared.panelSize))
                    .frame(maxHeight: .infinity)
                    .foregroundColor(
                        key.label == "⇪" && pressedKeys.contains("⇪") ? 
                            optShiftColor : 
                            .primary
                    )
            } else if SettingsManager.shared.showAllSpecialChars && (key.opt != nil || key.optShift != nil) {
                VStack(spacing: 2 * SettingsManager.shared.panelSize) {
                    // Main character - always show the displayedLabel to handle shift properly
                    Text(displayedLabel)
                        .font(.system(size: 18 * SettingsManager.shared.panelSize, weight: .medium))
                        .foregroundColor(mode == 0 ? .primary : .primary.opacity(0.5))  // Grey out when special chars active
                    
                    Spacer().frame(height: 4 * SettingsManager.shared.panelSize)
                    
                    // Special characters in horizontal layout
                    HStack(spacing: 8 * SettingsManager.shared.panelSize) {
                        // Option character
                        if let opt = key.opt {
                            Text(opt)
                                .font(.system(
                                    size: (mode == 1 ? 18 : 12) * SettingsManager.shared.panelSize,
                                    weight: mode == 1 ? .semibold : .medium
                                ))
                                .foregroundColor(mode == 1 ? optColor : optColor.opacity(0.75))
                                .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                                .scaleEffect(mode == 1 ? 1.15 : 1.0)
                        }
                        
                        // Option+Shift character
                        if let optShift = key.optShift {
                            Text(optShift)
                                .font(.system(
                                    size: (mode == 2 ? 18 : 12) * SettingsManager.shared.panelSize,
                                    weight: mode == 2 ? .semibold : .medium
                                ))
                                .foregroundColor(mode == 2 ? optShiftColor : optShiftColor.opacity(0.75))
                                .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5)
                                .scaleEffect(mode == 2 ? 1.15 : 1.0)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Text(displayedLabel)
                    .font(.system(size: 18 * SettingsManager.shared.panelSize, weight: .medium))
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: width, height: 75 * SettingsManager.shared.panelSize)
        .background(
            RoundedRectangle(cornerRadius: 6 * SettingsManager.shared.panelSize)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6 * SettingsManager.shared.panelSize)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
        .foregroundColor(isPressed ? .primary : .primary)
    }
    
    private var backgroundColor: Color {
        if key.label == "⇧" {
            if mode == 2 {
                return isPressed ? optShiftColor.opacity(0.3) : optShiftColor.opacity(0.1)
            } else if pressedKeys.contains("⇧") {
                return isPressed ? optShiftColor.opacity(0.3) : optShiftColor.opacity(0.1)
            } else {
                return isPressed ? optColor.opacity(0.3) : Color.secondary.opacity(0.1)
            }
        } else if key.label == "option" {
            return isPressed ? optColor.opacity(0.3) : Color.secondary.opacity(0.1)
        } else if key.label == "⇪" {
            return pressedKeys.contains("⇪") ? optShiftColor.opacity(0.3) : Color.secondary.opacity(0.1)
        } else if key.label == "⏎" || key.label == "⌫" {
            return isPressed ? SettingsManager.shared.colorPreset.highlightColor.opacity(0.3) : Color.secondary.opacity(0.1)
        }
        return isPressed ? SettingsManager.shared.colorPreset.highlightColor.opacity(0.3) : Color.secondary.opacity(0.1)
    }
}

private struct PressedKeysKey: EnvironmentKey {
    static let defaultValue: Set<String> = []
}

extension EnvironmentValues {
    var pressedKeys: Set<String> {
        get { self[PressedKeysKey.self] }
        set { self[PressedKeysKey.self] = newValue }
    }
}

public struct BlurPaneView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var pressedKeys: Set<String> = []
    @State private var selectedMode: Int = 0 // 0: normal, 1: opt, 2: opt+shift
    
    private let layout = KeyboardLayout.qwertzDE
    private let rows: [[KeyModel]]
    
    public init() {
        self.rows = [
            layout.row2,
            layout.row3,
            layout.row4,
            layout.row5,
            layout.row6
        ]
    }
    
    public var body: some View {
        VStack(spacing: 6 * SettingsManager.shared.panelSize) {
            // Keyboard Rows
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 4 * SettingsManager.shared.panelSize) {
                    // Add row-specific horizontal offset
                    switch rowIndex {
                    case 1: // QWERTZ row
                        Spacer().frame(width: 12 * SettingsManager.shared.panelSize)
                    case 2: // ASDF row - align 'a' with 'q'
                        Spacer().frame(width: 20 * SettingsManager.shared.panelSize)
                    case 3: // YXCV row
                        Spacer().frame(width: 32 * SettingsManager.shared.panelSize)
                    case 4: // Bottom row
                        Spacer().frame(width: 8 * SettingsManager.shared.panelSize)
                    default:
                        EmptyView()
                    }
                    
                    ForEach(row) { key in
                        KeyView(
                            key: key,
                            isPressed: pressedKeys.contains(key.label),
                            width: keyWidth(for: key, in: rowIndex),
                            mode: selectedMode
                        )
                        .onTapGesture {
                            if SettingsManager.shared.enableMouseClicks {
                                handleKeyClick(key)
                            }
                        }
                    }
                    
                    // Balance the spacing on the right side
                    switch rowIndex {
                    case 1: // QWERTZ row
                        Spacer().frame(width: 12 * SettingsManager.shared.panelSize)
                    case 2: // ASDF row
                        Spacer().frame(width: 20 * SettingsManager.shared.panelSize)
                    case 3: // YXCV row
                        Spacer().frame(width: 32 * SettingsManager.shared.panelSize)
                    case 4: // Bottom row
                        Spacer().frame(width: 8 * SettingsManager.shared.panelSize)
                    default:
                        EmptyView()
                    }
                }
                // Add vertical offset for each row
                .offset(y: CGFloat(rowIndex)) // Fixed vertical staggering
            }
            
            Spacer().frame(height: 6 * SettingsManager.shared.panelSize)
            
            // Legend and Settings Row at bottom
            HStack {
                // Legend for modifier keys
                HStack(spacing: 16 * SettingsManager.shared.panelSize) {
                    HStack(spacing: 6 * SettingsManager.shared.panelSize) {
                        Circle()
                            .fill(SettingsManager.shared.colorPreset.optColor)
                            .frame(width: 8 * SettingsManager.shared.panelSize, height: 8 * SettingsManager.shared.panelSize)
                        Image(systemName: "option")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                        Text("Option")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                            .foregroundColor(.secondary)
                    }.padding(.leading, 10 * SettingsManager.shared.panelSize)
                    
                    HStack(spacing: 6 * SettingsManager.shared.panelSize) {
                        Circle()
                            .fill(SettingsManager.shared.colorPreset.optShiftColor)
                            .frame(width: 8 * SettingsManager.shared.panelSize, height: 8 * SettingsManager.shared.panelSize)
                        Image(systemName: "option")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                        Text("+")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                            .foregroundColor(.secondary)
                        Image(systemName: "shift")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                        Text("Option+Shift")
                            .font(.system(size: 11 * SettingsManager.shared.panelSize))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("HidePanel"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 14 * SettingsManager.shared.panelSize))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .padding(.top, 6)
        }
        .environment(\.pressedKeys, pressedKeys)
        .padding(.horizontal, 2 * SettingsManager.shared.panelSize)
        .padding(.top, 28 * SettingsManager.shared.panelSize)
        .padding(.bottom, 8 * SettingsManager.shared.panelSize)
        .background(
            ZStack {
                Color(.windowBackgroundColor)
                    .opacity(SettingsManager.shared.useTransparency ? 0.95 : 1.0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            setupCallbacks()
            checkInitialModifierState()
        }
        .onDisappear {
            notificationManager.cleanup()
            pressedKeys.removeAll()
            selectedMode = 0
        }
    }
    
    private func setupCallbacks() {
        notificationManager.onKeyPress = { notification in
            if let key = notification.object as? String {
                // Check for caps lock state changes
                if key == "⇪" {
                    // Don't add animation for keyboard press
                    let flags = NSEvent.modifierFlags
                    if flags.contains(.capsLock) {
                        pressedKeys.insert(key)
                    } else {
                        pressedKeys.remove(key)
                    }
                    return
                }
                
                if !pressedKeys.contains(key) {
                    pressedKeys.insert(key)
                    updateMode()
                }
            }
        }
        
        notificationManager.onKeyRelease = { notification in
            if let key = notification.object as? String {
                if pressedKeys.contains(key) {
                    pressedKeys.remove(key)
                    updateMode()
                }
            }
        }
        
        // Add a timer to periodically check caps lock state
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let flags = NSEvent.modifierFlags
            if flags.contains(.capsLock) && !pressedKeys.contains("⇪") {
                pressedKeys.insert("⇪")
            } else if !flags.contains(.capsLock) && pressedKeys.contains("⇪") {
                pressedKeys.remove("⇪")
            }
        }
    }
    
    private func keyWidth(for key: KeyModel, in rowIndex: Int) -> CGFloat {
        let baseWidth: CGFloat
        switch key.label {
        case "⌫", "⏎": baseWidth = 90
        case "⇪", "⇧": baseWidth = 100
        case " ": baseWidth = 300
        default: baseWidth = rowIndex == 4 ? 70 : 60 // Bottom row keys are wider
        }
        return baseWidth * SettingsManager.shared.panelSize
    }
    
    private func checkInitialModifierState() {
        let flags = NSEvent.modifierFlags
        if flags.contains(.option) {
            pressedKeys.insert("option")
            selectedMode = 1
        }
        if flags.contains(.shift) {
            pressedKeys.insert("⇧")
            if flags.contains(.option) {
                selectedMode = 2
            }
        }
        if flags.contains(.capsLock) {
            pressedKeys.insert("⇪")
        }
    }
    
    private func updateMode() {
        let newMode = if pressedKeys.contains("option") {
            // If caps lock is on, treat it like shift is pressed for opt mode
            (pressedKeys.contains("⇧") || pressedKeys.contains("⇪")) ? 2 : 1
        } else {
            0
        }
        
        if selectedMode != newMode {
            selectedMode = newMode
        }
    }
    
    private func handleKeyClick(_ key: KeyModel) {
        // Handle modifier keys
        if key.label == "option" {
            selectedMode = selectedMode == 1 ? 0 : 1
            if selectedMode == 1 {
                pressedKeys.insert("option")
            } else {
                pressedKeys.remove("option")
            }
            return
        } else if key.label == "⇧" || key.label == "⇪" {  // Treat caps lock same as shift in click mode
            if selectedMode == 1 {  // If option is active
                selectedMode = 2
                pressedKeys.insert("⇧")
            } else if selectedMode == 2 {  // If already in opt+shift
                selectedMode = 1
                pressedKeys.remove("⇧")
            } else {  // Normal mode
                if pressedKeys.contains("⇧") {
                    pressedKeys.remove("⇧")
                } else {
                    pressedKeys.insert("⇧")
                }
                updateMode()
            }
            return
        }
        
        // Handle special keys
        switch key.label {
        case "⏎", "⌫", "⇥":
            let keyCode: UInt16
            switch key.label {
            case "⏎": keyCode = 0x24  // Return
            case "⌫": keyCode = 0x33  // Delete
            case "⇥": keyCode = 0x30  // Tab
            default: keyCode = 0
            }
            
            // Show pressed state
            pressedKeys.insert(key.label)
            
            let src = CGEventSource(stateID: .hidSystemState)
            let keyDownEvent = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
            let keyUpEvent = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
            
            keyDownEvent?.post(tap: .cgAnnotatedSessionEventTap)
            keyUpEvent?.post(tap: .cgAnnotatedSessionEventTap)
            
            // Remove pressed state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pressedKeys.remove(key.label)
            }
            return
            
        case "command", "control", "fn":
            // These keys are just for visual feedback
            return
            
        default:
            // Handle regular character keys
            // Temporarily show the key as pressed
            pressedKeys.insert(key.label)
            
            // Get the correct character based on mode
            let character: String
            if selectedMode == 1 {
                character = key.opt ?? key.label
            } else if selectedMode == 2 {
                character = key.optShift ?? key.opt ?? key.label
            } else if pressedKeys.contains("⇧") || pressedKeys.contains("⇪") {
                character = key.shift ?? key.label.uppercased()
            } else {
                character = key.label
            }
            
            // Post the character insertion notification
            NotificationCenter.default.post(
                name: NSNotification.Name("InsertCharacter"),
                object: character
            )
            
            // Remove the pressed state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pressedKeys.remove(key.label)
            }
        }
    }
}
