//
//  Error.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import CNimBLE

/// NimBLE error codes
public struct NimBLEError: Error, RawRepresentable, Equatable, Hashable, Sendable {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

// MARK: - CustomStringConvertible

extension NimBLEError: CustomStringConvertible {
    
    public var description: String {
        rawValue.description
    }
}

// MARK: - Error Codes

public extension NimBLEError {
    
    /// Operation failed and should be retried later.
    static var retryAgain: NimBLEError { NimBLEError(rawValue: BLE_HS_EAGAIN) }
    
    /// Operation already in progress.
    static var alreadyInProgress: NimBLEError { NimBLEError(rawValue: BLE_HS_EALREADY) }
    
    /// Invalid parameter.
    static var invalidParameter: NimBLEError { NimBLEError(rawValue: BLE_HS_EINVAL) }
    
    /// Message too long.
    static var messageSize: NimBLEError { NimBLEError(rawValue: BLE_HS_EMSGSIZE) }

    /// No such entry.
    static var noEntry: NimBLEError { NimBLEError(rawValue: BLE_HS_ENOENT) }
    
    /// Out of memory.
    static var outOfMemory: NimBLEError { NimBLEError(rawValue: BLE_HS_ENOMEM) }
}

// MARK: - Extensions

internal extension Int32 {
    
    func throwsError() throws(NimBLEError) {
        guard self == 0 else {
            throw NimBLEError(rawValue: self)
        }
    }
}
