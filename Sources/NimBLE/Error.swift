//
//  Error.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

/// NimBLE error codes
public struct NimBLEError: Error, RawRepresentable, Equatable, Hashable, Sendable {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

internal extension Int32 {
    
    func throwsError() throws(NimBLEError) {
        guard self == 0 else {
            throw NimBLEError(rawValue: self)
        }
    }
}
