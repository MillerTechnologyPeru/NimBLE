//
//  NimBLE.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import Bluetooth
import CNimBLE

/// NimBLE Bluetooth Stack
public struct NimBLE: ~Copyable {
    
    internal let context: UnsafeMutablePointer<Context>
    
    public init() {
        self.init(initializePort: true)
    }
    
    internal init(initializePort: Bool) {
        // Initialize NimBLE stack
        if initializePort {
            nimble_port_init()
        }
        // Allocate context on heap for callbacks
        context = .allocate(capacity: 1)
        context.pointee = Context()
    }
    
    deinit {
        context.deinitialize(count: 1)
        context.deallocate()
    }
    
    /// Runs the event loop
    public func run() {
        nimble_port_run()
    }
    
}

internal extension NimBLE {
    
    struct Context {
        
        var advertisment = LowEnergyAdvertisingData()
        
        var scanResponse = LowEnergyAdvertisingData()
        
        /// Callback to handle GATT read requests.
        //public var willRead: ((GATTReadRequest<Central>) -> ATTError?)?
        
        /// Callback to handle GATT write requests.
        //public var willWrite: ((GATTWriteRequest<Central>) -> ATTError?)?
        
        /// Callback to handle post-write actions for GATT write requests.
        //public var didWrite: ((GATTWriteConfirmation<Central>) -> ())?
    }
}
