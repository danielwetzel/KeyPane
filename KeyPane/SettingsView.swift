//
//  SettingsView.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//


import SwiftUI
import ServiceManagement
import Observation

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var launchAtLogin: Bool = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("General")
                            .font(.headline)
                        if #available(macOS 14.0, *) {
                            Toggle("Launch at Login", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) { oldValue, newValue in
                                    setAutoLaunch(enabled: newValue)
                                }
                        } else {
                            Toggle("Launch at Login", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) { newValue in
                                    setAutoLaunch(enabled: newValue)
                                }
                        }
                        Toggle("Show in Menu Bar", isOn: $settings.showInMenuBar)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Privacy Mode", isOn: $settings.privacyMode)
                            Text("No accessibility permissions required, but key highlighting disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 12)
                
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Panel Behavior")
                            .font(.headline)
                        Toggle("Keep panel open after key press", isOn: $settings.keepPanelOpen)
                        Toggle("Toggle panel with double-opt (vs. hold)", isOn: $settings.toggleMode)
                        Toggle("Enable mouse clicks for key input", isOn: $settings.enableMouseClicks)
                        Toggle("Use transparency effect", isOn: $settings.useTransparency)
                        Toggle("Always show special characters", isOn: $settings.showAllSpecialChars)
                        Toggle("Click outside panel to close", isOn: $settings.clickToClose)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Panel Size")
                                Text(sizeLabel(for: settings.panelSize))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Reset") {
                                    settings.panelSize = 1.0
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.accentColor)
                            }
                            Slider(
                                value: $settings.panelSize,
                                in: 0.5...1.5,
                                step: 0.1
                            )
                        }
                    }
                }
                .padding(.bottom, 12)
                
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Color Theme")
                            .font(.headline)
                        ForEach(ColorPreset.allCases, id: \.self) { preset in
                            Button(action: {
                                settings.colorPreset = preset
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: settings.colorPreset == preset ? "circle.inset.filled" : "circle")
                                        .foregroundColor(settings.colorPreset == preset ? .accentColor : .secondary)
                                    
                                    Text(preset.rawValue)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(preset.optColor)
                                            .frame(width: 16, height: 16)
                                        Circle()
                                            .fill(preset.optShiftColor)
                                            .frame(width: 16, height: 16)
                                        Circle()
                                            .fill(preset.highlightColor)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Button("Quit KeyPane") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.bottom)
        }
        .padding(12)
        .frame(width: 400, height: 500)
        .onAppear {
            launchAtLogin = isAutoLaunchEnabled()
        }
    }
    
    // MARK: - Auto-Launch Helper Methods
    
    func setAutoLaunch(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to toggle auto-launch: \(error)")
            }
        } else {
            print("Auto-launch not supported on this macOS version.")
        }
    }
    
    func isAutoLaunchEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return false
        }
    }
    
    private func sizeLabel(for size: Double) -> String {
        switch size {
        case 0.5..<0.7: return "Tiny"
        case 0.7..<0.9: return "Small"
        case 0.9: return "Normal"
        case 1.0: return "Default"
        case 1.1: return "Normal"
        case 1.2..<1.4: return "Large"
        case 1.4..<1.6: return "Huge"
        default: return ""
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
