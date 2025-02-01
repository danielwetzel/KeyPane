//
//  NotificationManager.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Foundation

class NotificationManager: ObservableObject {
    private var keyPressToken: NotificationToken?
    private var keyReleaseToken: NotificationToken?
    
    var onKeyPress: ((Notification) -> Void)?
    var onKeyRelease: ((Notification) -> Void)?
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        keyPressToken = notificationCenter.addObserver(
            forName: NSNotification.Name("KeyPressed"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.onKeyPress?(notification)
        }
        
        keyReleaseToken = notificationCenter.addObserver(
            forName: NSNotification.Name("KeyReleased"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.onKeyRelease?(notification)
        }
    }
    
    func cleanup() {
        if let token = keyPressToken {
            NotificationCenter.default.removeObserver(token)
            keyPressToken = nil
        }
        if let token = keyReleaseToken {
            NotificationCenter.default.removeObserver(token)
            keyReleaseToken = nil
        }
    }
    
    deinit {
        cleanup()
    }
} 