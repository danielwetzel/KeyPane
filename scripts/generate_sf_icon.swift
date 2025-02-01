import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Create rounded rect path with Apple-like corner radius (approximately 20% of icon size)
let cornerRadius: CGFloat = 215 // Reduced to match Apple's standard icon corner radius
let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: cornerRadius, yRadius: cornerRadius)
path.addClip()

// Fill white background
NSColor.white.setFill()
NSRect(origin: .zero, size: size).fill()

// Draw keyboard symbol
let config = NSImage.SymbolConfiguration(pointSize: 700, weight: .regular)
if let symbol = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    // Get the natural size of the symbol to maintain aspect ratio
    let symbolSize = symbol.size
    let aspectRatio = symbolSize.width / symbolSize.height
    
    // Calculate dimensions to maintain aspect ratio
    let targetHeight = 500.0
    let targetWidth = targetHeight * aspectRatio
    
    // Center the symbol in the square
    let x = (size.width - targetWidth) / 2
    let y = (size.height - targetHeight) / 2
    
    symbol.draw(in: NSRect(x: x, y: y, width: targetWidth, height: targetHeight))
}

image.unlockFocus()

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try! pngData.write(to: URL(fileURLWithPath: "KeyPane/Assets.xcassets/AppIcon.appiconset/icon_1024.png"))
}

// Generate other sizes
let sizes = [16, 32, 64, 128, 256, 512]
for size in sizes {
    let task = Process()
    task.launchPath = "/usr/bin/sips"
    task.currentDirectoryPath = "KeyPane/Assets.xcassets/AppIcon.appiconset"
    task.arguments = ["-z", "\(size)", "\(size)", "icon_1024.png", "--out", "icon_\(size).png"]
    try! task.run()
    task.waitUntilExit()
} 