import SwiftUI

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 96, height: 96)
            
            VStack(spacing: 8) {
                Text("KeyPane")
                    .font(.title)
                    .bold()
                
                Text("Version \(version) (\(build))")
                    .font(.system(size: 13))
                
                Text("© 2025 Daniel Wetzel")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
        .frame(width: 220, height: 220)
        .fixedSize()
    }
} 