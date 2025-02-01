//
//  KeyboardLayout.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Foundation

struct KeyboardLayout {
    let row2: [KeyModel]
    let row3: [KeyModel]
    let row4: [KeyModel]
    let row5: [KeyModel]
    let row6: [KeyModel]
    
    private struct LayoutKey: Codable {
        let key: String
        let opt: String?
        let optShift: String?
        let shift: String?
        
        func toKeyModel() -> KeyModel {
            KeyModel(key, opt: opt, optShift: optShift, shift: shift)
        }
    }
    
    private struct LayoutData: Codable {
        let row2: [LayoutKey]
        let row3: [LayoutKey]
        let row4: [LayoutKey]
        let row5: [LayoutKey]
        let row6: [LayoutKey]
    }
    
    static let qwertzDE: KeyboardLayout = {
        // First try to load from the bundle
        if let url = Bundle.main.url(forResource: "qwertzDE", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let layoutData = try? JSONDecoder().decode(LayoutData.self, from: data) {
            return KeyboardLayout(
                row2: layoutData.row2.map { $0.toKeyModel() },
                row3: layoutData.row3.map { $0.toKeyModel() },
                row4: layoutData.row4.map { $0.toKeyModel() },
                row5: layoutData.row5.map { $0.toKeyModel() },
                row6: layoutData.row6.map { $0.toKeyModel() }
            )
        }
        
        // If bundle load fails, try to load from the local file system during development
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        print("Current directory: \(currentDirectoryPath)")
        
        let possiblePaths = [
            "KeyPane/Resources/qwertzDE.json",
            "Resources/qwertzDE.json",
            "layout/qwertzDE.json",
            "KeyPane/layout/qwertzDE.json"
        ]
        
        for path in possiblePaths {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let layoutData = try? JSONDecoder().decode(LayoutData.self, from: data) {
                print("Found layout file at: \(path)")
                return KeyboardLayout(
                    row2: layoutData.row2.map { $0.toKeyModel() },
                    row3: layoutData.row3.map { $0.toKeyModel() },
                    row4: layoutData.row4.map { $0.toKeyModel() },
                    row5: layoutData.row5.map { $0.toKeyModel() },
                    row6: layoutData.row6.map { $0.toKeyModel() }
                )
            }
        }
        
        fatalError("Failed to load keyboard layout from JSON. Bundle path: \(Bundle.main.bundlePath)")
    }()
} 
