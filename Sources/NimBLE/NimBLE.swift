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
    
    public var log: (@Sendable (String) -> ())? {
        get { context.pointee.log }
        set { context.pointee.log = newValue }
    }
    
    /// Runs the event loop
    public func run() {
        nimble_port_run()
    }
    
    public func run(while body: () -> (Bool)) {
        let time = ble_npl_time_t(BLE_NPL_TIME_FOREVER)
        let dflt = nimble_port_get_dflt_eventq()
        while body() {
            let event = ble_npl_eventq_get(dflt, time)
            ble_npl_event_run(event)
        }
    }
}

internal extension NimBLE {
    
    struct Context {
        
        var log: (@Sendable (String) -> ())?
        
        var gap = GAP.Context()
        
        var gattServer = GATTServer.Context()
        
        
    }
}
