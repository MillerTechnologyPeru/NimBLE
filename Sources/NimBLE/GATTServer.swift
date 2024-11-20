//
//  GATTServer.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import Bluetooth
import BluetoothGATT
import GATT
import CNimBLE

public extension NimBLE {
    
    var server: GATTServer { GATTServer(context: context) }
}

/// NimBLE GATT Server interface.
public struct GATTServer {
    
    internal struct Context {
        
        var services = [ble_gatt_svc_def]()
        
        var characteristics = [ble_gatt_chr_def]()
        
        var buffers = [[UInt8]]()
        
        /// Callback to handle GATT read requests.
        var willRead: ((GATTReadRequest<Central, [UInt8]>) -> ATTError?)?
        
        /// Callback to handle GATT write requests.
        var willWrite: ((GATTWriteRequest<Central, [UInt8]>) -> ATTError?)?
        
        /// Callback to handle post-write actions for GATT write requests.
        var didWrite: ((GATTWriteConfirmation<Central, [UInt8]>) -> ())?
    }
    
    // MARK: - Properties
    
    internal let context: UnsafeMutablePointer<NimBLE.Context>
    
    /// Callback to handle GATT read requests.
    public var willRead: ((GATTReadRequest<Central, [UInt8]>) -> ATTError?)? {
        get { context.pointee.gattServer.willRead }
        set { context.pointee.gattServer.willRead = newValue }
    }
    
    /// Callback to handle GATT write requests.
    public var willWrite: ((GATTWriteRequest<Central, [UInt8]>) -> ATTError?)? {
        get { context.pointee.gattServer.willWrite }
        set { context.pointee.gattServer.willWrite = newValue }
    }
    
    /// Callback to handle post-write actions for GATT write requests.
    public var didWrite: ((GATTWriteConfirmation<Central, [UInt8]>) -> ())? {
        get { context.pointee.gattServer.didWrite }
        set { context.pointee.gattServer.didWrite = newValue }
    }
    
    // MARK: - Methods
    
    public func start() throws(NimBLEError) {
        try ble_gatts_start().throwsError()
    }
    
    /// Attempts to add the specified service to the GATT database.
    public func add(services: [GATTAttribute<[UInt8]>.Service]) throws(NimBLEError) {
        var cServices = [ble_gatt_svc_def].init(repeating: .init(), count: services.count + 1)
        var buffers = [[UInt8]]()
        for (serviceIndex, service) in services.enumerated() {
            // set type
            cServices[serviceIndex].type = service.isPrimary ? UInt8(BLE_GATT_SVC_TYPE_PRIMARY) : UInt8(BLE_GATT_SVC_TYPE_SECONDARY)
            // set uuid
            let serviceUUID = ble_uuid_any_t(service.uuid)
            withUnsafeBytes(of: serviceUUID) {
                let buffer = [UInt8]($0)
                buffers.append(buffer)
                buffer.withUnsafeBytes {
                    cServices[serviceIndex].uuid = .init(OpaquePointer($0.baseAddress))
                }
            }
            assert(ble_uuid_any_t(cServices[serviceIndex].uuid) == serviceUUID)
            assert(serviceUUID.dataLength == service.uuid.dataLength)
            // add characteristics
            var cCharacteristics = [ble_gatt_chr_def].init(repeating: .init(), count: service.characteristics.count + 1)
            for (characteristicIndex, characteristic) in service.characteristics.enumerated() {
                // set callback
                cCharacteristics[characteristicIndex].access_cb = _ble_gatt_access
                // set UUID
                let characteristicUUID = ble_uuid_any_t(characteristic.uuid)
                withUnsafeBytes(of: characteristicUUID) {
                    let buffer = [UInt8]($0)
                    buffers.append(buffer)
                    buffer.withUnsafeBytes {
                        cCharacteristics[characteristicIndex].uuid = .init(OpaquePointer($0.baseAddress))
                    }
                }
            }
            cCharacteristics.withUnsafeBufferPointer {
                cServices[serviceIndex].characteristics = $0.baseAddress
            }
            self.context.pointee.gattServer.characteristics = cCharacteristics
        }
        // queue service registration
        try ble_gatts_count_cfg(cServices).throwsError()
        try ble_gatts_add_svcs(cServices).throwsError()
        // store buffers
        cServices.removeLast() // nil terminator
        self.context.pointee.gattServer.services = cServices
        self.context.pointee.gattServer.buffers = buffers
    }
    
    /// Removes the service with the specified handle.
    public func remove(service: UInt16) {
        // iterate all services and find the specified handle
    }
    
    /// Clears the local GATT database.
    public func removeAllServices() {
        ble_gatts_reset()
        self.context.pointee.gattServer.buffers.removeAll()
        self.context.pointee.gattServer.services.removeAll()
    }
    
    public func dump() {
        ble_gatts_show_local()
    }
}

// typedef int ble_gatt_access_fn(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt *ctxt, void *arg);
internal func _ble_gatt_access(
    conn_handle: UInt16,
    attr_handle: UInt16,
    accessContext: UnsafeMutablePointer<ble_gatt_access_ctxt>?,
    context: UnsafeMutableRawPointer?
) -> CInt {
    
    return 0
}
