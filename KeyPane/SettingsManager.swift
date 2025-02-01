//
//  SettingsManager.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Foundation
import SwiftUI

enum ColorPreset: String, CaseIterable {
    case orangeRed = "Orange & Red"
    case blueViolet = "Blue & Violet"
    case greenTeal = "Green & Teal"
    case purplePink = "Purple & Pink"
    
    var optColor: Color {
        switch self {
        case .orangeRed: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .blueViolet: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .greenTeal: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .purplePink: return Color(red: 0.8, green: 0.3, blue: 0.8)
        }
    }
    
    var optShiftColor: Color {
        switch self {
        case .orangeRed: return Color(red: 0.8, green: 0.0, blue: 0.0)
        case .blueViolet: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .greenTeal: return Color(red: 0.0, green: 0.6, blue: 0.6)
        case .purplePink: return Color(red: 1.0, green: 0.2, blue: 0.6)
        }
    }
    
    var highlightColor: Color {
        switch self {
        case .orangeRed: return Color(red: 0.95, green: 0.7, blue: 0.0)  // Darker yellow
        case .blueViolet: return Color(red: 0.3, green: 0.8, blue: 1.0) // Light blue
        case .greenTeal: return Color(red: 0.4, green: 1.0, blue: 0.4)  // Light green
        case .purplePink: return Color(red: 1.0, green: 0.4, blue: 0.8) // Light pink
        }
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var toggleMode: Bool {
        didSet {
            UserDefaults.standard.set(toggleMode, forKey: "toggleMode")
        }
    }
    
    @Published var keepPanelOpen: Bool {
        didSet {
            UserDefaults.standard.set(keepPanelOpen, forKey: "keepPanelOpen")
        }
    }
    
    @Published var enableMouseClicks: Bool {
        didSet {
            UserDefaults.standard.set(enableMouseClicks, forKey: "enableMouseClicks")
        }
    }
    
    @Published var showAllSpecialChars: Bool {
        didSet {
            UserDefaults.standard.set(showAllSpecialChars, forKey: "showAllSpecialChars")
        }
    }
    
    @Published var useTransparency: Bool {
        didSet {
            UserDefaults.standard.set(useTransparency, forKey: "useTransparency")
        }
    }
    
    @Published var colorPreset: ColorPreset {
        didSet {
            UserDefaults.standard.set(colorPreset.rawValue, forKey: "colorPreset")
        }
    }
    
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: "showInMenuBar")
            NotificationCenter.default.post(name: NSNotification.Name("MenuBarVisibilityChanged"), object: showInMenuBar)
        }
    }
    
    @Published var panelSize: Double {
        didSet {
            // Clamp the value between 0.5 and 1.5
            let clampedValue = max(0.5, min(panelSize, 1.5))
            if clampedValue != panelSize {
                panelSize = clampedValue
                return
            }
            UserDefaults.standard.set(panelSize, forKey: "panelSize")
            NotificationCenter.default.post(name: NSNotification.Name("PanelSizeChanged"), object: panelSize)
        }
    }
    
    @Published var clickToClose: Bool {
        didSet {
            UserDefaults.standard.set(clickToClose, forKey: "clickToClose")
        }
    }
    
    @Published var privacyMode: Bool {
        didSet {
            UserDefaults.standard.set(privacyMode, forKey: "privacyMode")
            NotificationCenter.default.post(name: NSNotification.Name("PrivacyModeChanged"), object: privacyMode)
        }
    }
    
    private init() {
        // Initialize properties from UserDefaults
        self.toggleMode = UserDefaults.standard.bool(forKey: "toggleMode")
        self.keepPanelOpen = UserDefaults.standard.bool(forKey: "keepPanelOpen")
        self.enableMouseClicks = UserDefaults.standard.bool(forKey: "enableMouseClicks")
        self.showAllSpecialChars = UserDefaults.standard.bool(forKey: "showAllSpecialChars")
        self.useTransparency = UserDefaults.standard.bool(forKey: "useTransparency")
        self.showInMenuBar = UserDefaults.standard.bool(forKey: "showInMenuBar")
        self.panelSize = UserDefaults.standard.double(forKey: "panelSize")
        self.clickToClose = UserDefaults.standard.bool(forKey: "clickToClose")
        self.privacyMode = UserDefaults.standard.bool(forKey: "privacyMode")
        
        // Initialize colorPreset
        if let rawValue = UserDefaults.standard.string(forKey: "colorPreset"),
           let preset = ColorPreset(rawValue: rawValue) {
            self.colorPreset = preset
        } else {
            self.colorPreset = .orangeRed
        }
        
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: "toggleMode") == nil {
            UserDefaults.standard.set(false, forKey: "toggleMode")
        }
        if UserDefaults.standard.object(forKey: "keepPanelOpen") == nil {
            UserDefaults.standard.set(false, forKey: "keepPanelOpen")
        }
        if UserDefaults.standard.object(forKey: "enableMouseClicks") == nil {
            UserDefaults.standard.set(true, forKey: "enableMouseClicks")
        }
        if UserDefaults.standard.object(forKey: "showAllSpecialChars") == nil {
            UserDefaults.standard.set(true, forKey: "showAllSpecialChars")
        }
        if UserDefaults.standard.object(forKey: "useTransparency") == nil {
            UserDefaults.standard.set(true, forKey: "useTransparency")
        }
        if UserDefaults.standard.object(forKey: "showInMenuBar") == nil {
            UserDefaults.standard.set(true, forKey: "showInMenuBar")
        }
        if UserDefaults.standard.object(forKey: "colorPreset") == nil {
            UserDefaults.standard.set(ColorPreset.orangeRed.rawValue, forKey: "colorPreset")
        }
        if UserDefaults.standard.object(forKey: "panelSize") == nil {
            UserDefaults.standard.set(1.0, forKey: "panelSize")
            self.panelSize = 1.0
        }
        if UserDefaults.standard.object(forKey: "clickToClose") == nil {
            UserDefaults.standard.set(true, forKey: "clickToClose")  // Enable by default
        }
        if UserDefaults.standard.object(forKey: "privacyMode") == nil {
            UserDefaults.standard.set(false, forKey: "privacyMode")  // Default mode by default
        }
    }
} 