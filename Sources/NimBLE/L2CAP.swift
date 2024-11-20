//
//  L2CAP.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/11/24.
//

import Bluetooth
import CNimBLE

public extension NimBLE {
    
    enum L2CAP: ~Copyable {
        
        case server(Server)
        case channel(Channel)
    }
}

public extension NimBLE.L2CAP {
    
    struct Server: ~Copyable {
        
        struct Context {
            
            var pending = [NimBLE.L2CAP.Channel.Context]()
        }
        
        internal let context: UnsafeMutablePointer<Context>
        
        init(psm: UInt16 = 0x001F, mtu: UInt16 = 23) throws(NimBLEError) {
            // Allocate context on heap for callbacks
            context = .allocate(capacity: 1)
            context.initialize(to: Context())
            // create socket
            let contextPointer = UnsafeMutableRawPointer(self.context)
            //ble_l2cap_create_server(psm, mtu, _ble_l2cap_event_server, contextPointer)//.throwsError()
        }
        
        deinit {
            context.deinitialize(count: 1)
            context.deallocate()
        }
        
        func accept() throws(NimBLEError) -> NimBLE.L2CAP.Channel {
            guard context.pointee.pending.isEmpty else {
                throw .retryAgain
            }
            let connectionContext = context.pointee.pending.removeFirst()
            return NimBLE.L2CAP.Channel(connectionContext)
        }
    }
}

public extension NimBLE.L2CAP {
    
    struct Channel: ~Copyable {
        
        struct Context {
            
            let handle: UInt16
            
            var channel: OpaquePointer
        }
        
        internal var context: UnsafeMutablePointer<Context>
        
        internal init(_ context: Context) {
            self.context = .allocate(capacity: 1)
            self.context.initialize(to: context)
        }
        
        deinit {
            context.deinitialize(count: 1)
            context.deallocate()
            // disconnect
            try? disconnect()
        }
        
        func disconnect() throws(NimBLEError) {
            try ble_l2cap_disconnect(context.pointee.channel).throwsError()
        }
    }
}

internal extension NimBLE.L2CAP.Server.Context {
    
    mutating func event(_ event: ble_l2cap_event) throws(NimBLEError) {
        switch Int32(event.type) {
        case BLE_L2CAP_EVENT_COC_CONNECTED:
            try Int32(event.connect.status).throwsError()
            let handle = event.connect.conn_handle
            self.pending.append(.init(handle: handle, channel: event.connect.chan))
        default:
            break
        }
    }
}

internal func _ble_l2cap_event_server(_ event: UnsafePointer<ble_l2cap_event>?, _ contextPointer: UnsafeMutableRawPointer?) -> CInt {
    guard let context = contextPointer?.assumingMemoryBound(to: NimBLE.L2CAP.Server.Context.self), let event = event?.pointee else {
        return 0
    }
    do {
        try context.pointee.event(event)
    }
    catch {
        return error.rawValue
    }
    return 0
}

internal extension NimBLE.L2CAP.Channel.Context {
    
    mutating func event(_ event: ble_l2cap_event) throws(NimBLEError) {
        switch Int32(event.type) {
        case BLE_L2CAP_EVENT_COC_CONNECTED:
            try Int32(event.connect.status).throwsError()
            let handle = event.connect.conn_handle
            
        default:
            break
        }
    }
}

internal func _ble_l2cap_event_channel(_ event: UnsafePointer<ble_l2cap_event>?, _ contextPointer: UnsafeMutableRawPointer?) -> CInt {
    guard let context = contextPointer?.assumingMemoryBound(to: NimBLE.L2CAP.Channel.Context.self), let event = event?.pointee else {
        return 0
    }
    do {
        try context.pointee.event(event)
    }
    catch {
        return error.rawValue
    }
    return 0
}
