//
//  GATTServer.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import Bluetooth
import BluetoothGATT
//import GATT
import CNimBLE

public extension NimBLE {
    
    var server: GATTServer { GATTServer(context: context) }
}

/// NimBLE GATT Server interface.
public struct GATTServer {
    
    // MARK: - Properties
    
    internal let context: UnsafeMutablePointer<NimBLE.Context>
    
    /*
    /// Callback to handle GATT read requests.
    public var willRead: ((GATTReadRequest<Central>) -> ATTError?)?
    
    /// Callback to handle GATT write requests.
    public var willWrite: ((GATTWriteRequest<Central>) -> ATTError?)?
    
    /// Callback to handle post-write actions for GATT write requests.
    public var didWrite: ((GATTWriteConfirmation<Central>) -> ())?
    */
    
    // MARK: - Methods
    
    public func start() throws(NimBLEError) {
        try ble_gatts_start().throwsError()
    }
    
    /// Attempts to add the specified service to the GATT database.
    public func add(services: [GATTAttribute.Service]) throws(NimBLEError) {
        var cServices = [ble_gatt_svc_def].init(repeating: .init(), count: services.count + 1)
        var buffers = [[UInt8]]()
        // TODO: Free memory
        for (serviceIndex, service) in services.enumerated() {
            cServices[serviceIndex].type = service.primary ? UInt8(BLE_GATT_SVC_TYPE_PRIMARY) : UInt8(BLE_GATT_SVC_TYPE_SECONDARY)
            let serviceUUID = ble_uuid_any_t(service.uuid)
            withUnsafeBytes(of: serviceUUID) {
                let buffer = [UInt8]($0)
                buffers.append(buffer)
                buffer.withUnsafeBytes {
                    cServices[serviceIndex].uuid = .init(OpaquePointer($0.baseAddress))
                }
            }
            assert(ble_uuid_any_t(cServices[serviceIndex].uuid) == serviceUUID)
            //assert(serviceUUID.dataLength == service.uuid.dataLength)
        }
        try withExtendedLifetime(buffers) { _ throws(NimBLEError) -> () in
            try ble_gatts_count_cfg(cServices).throwsError()
            try ble_gatts_add_svcs(cServices).throwsError()
        }
    }
    
    /// Removes the service with the specified handle.
    public func remove(service: UInt16) {
        // iterate all services and find the specified handle
    }
    
    /// Clears the local GATT database.
    public func removeAllServices() {
        ble_gatts_reset()
    }
    
    public func dump() {
        ble_gatts_show_local()
    }
}
