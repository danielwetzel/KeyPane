import SwiftUI
import ApplicationServices

struct AccessibilityPermissionView: View {
    @State private var hasPermissions = AXIsProcessTrusted()
    @State private var permissionCheckTimer: Timer?
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Accessibility Permission Required")
                .font(.title2)
                .bold()
            
            Text("KeyPane needs accessibility permissions to monitor keyboard input and show key highlights. You can either:")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Enable Accessibility Permission")
                        .bold()
                    
                    Button("Open System Settings") {
                        openSystemSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("2. Use Privacy Mode")
                        .bold()
                    
                    Text("Run without accessibility permissions (key highlighting disabled)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Enable Privacy Mode") {
                        settings.privacyMode = true
                        restartApp()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 300)
        }
        .padding(32)
        .frame(width: 400, height: 400)
        .onAppear {
            startPermissionMonitoring()
        }
        .onDisappear {
            stopPermissionMonitoring()
        }
    }
    
    private func startPermissionMonitoring() {
        // Check immediately and start monitoring
        checkPermissions()
        
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        let currentPermissions = AXIsProcessTrusted()
        if currentPermissions != hasPermissions {
            hasPermissions = currentPermissions
            if currentPermissions {
                stopPermissionMonitoring()
                restartApp()
            }
        }
    }
    
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    private func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
} 