//
//  NimBLE.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import CNimBLE

/// NimBLE Bluetooth Stack
public struct NimBLE: ~Copyable {
    
    public init() {
        nimble_port_init()
    }
    
    /// Runs the event loop
    public func run() {
        nimble_port_run()
    }
    
    deinit {
        
    }
}
