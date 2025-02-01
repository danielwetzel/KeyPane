//
//  KeyPaneApp.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import SwiftUI

@main
struct KeyPaneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}


