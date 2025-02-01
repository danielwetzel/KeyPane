//
//  KeyModel.swift
//  KeyPane
//
//  Created by Daniel Wetzel on 01.01.25.
//

import Foundation

public struct KeyModel: Identifiable, Hashable {
    public let id: String
    public let label: String
    let opt: String?
    let optShift: String?
    let shift: String?
    
    public init(_ label: String, opt: String? = nil, optShift: String? = nil, position: Int? = nil, shift: String? = nil) {
        self.label = label
        self.opt = opt
        self.optShift = optShift
        self.shift = shift
        // Always include position in ID to ensure uniqueness
        self.id = position != nil ? "\(label)_\(position)" : UUID().uuidString
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: KeyModel, rhs: KeyModel) -> Bool {
        lhs.id == rhs.id
    }
} 