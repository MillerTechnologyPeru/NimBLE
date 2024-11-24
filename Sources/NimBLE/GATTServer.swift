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
        
        var services = [GATTAttribute<[UInt8]>.Service]()
        
        var servicesBuffer = [ble_gatt_svc_def]()
        
        var characteristicsBuffers = [[ble_gatt_chr_def]]()
        
        var buffers = [[UInt8]]()
        
        var characteristicValueHandles = [[UInt16]]()
        
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
    
    internal func start() throws(NimBLEError) {
        try ble_gatts_start().throwsError()
    }
    
    /// Attempts to add the specified service to the GATT database.
    public func set(services: [GATTAttribute<[UInt8]>.Service]) throws(NimBLEError) -> [[UInt16]] {
        removeAllServices()
        var cServices = [ble_gatt_svc_def].init(repeating: .init(), count: services.count + 1)
        var characteristicsBuffers = [[ble_gatt_chr_def]].init(repeating: [], count: services.count)
        var buffers = [[UInt8]]()
        var valueHandles = [[UInt16]].init(repeating: [], count: services.count)
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
            var characteristicHandles = [UInt16](repeating: 0, count: service.characteristics.count)
            // add characteristics
            var cCharacteristics = [ble_gatt_chr_def].init(repeating: .init(), count: service.characteristics.count + 1)
            for (characteristicIndex, characteristic) in service.characteristics.enumerated() {
                // set flags
                cCharacteristics[characteristicIndex].flags = ble_gatt_chr_flags(characteristic.properties.rawValue)
                // set access callback
                cCharacteristics[characteristicIndex].access_cb = _ble_gatt_access
                cCharacteristics[characteristicIndex].arg = .init(context)
                // set UUID
                let characteristicUUID = ble_uuid_any_t(characteristic.uuid)
                withUnsafeBytes(of: characteristicUUID) {
                    let buffer = [UInt8]($0)
                    buffers.append(buffer)
                    buffer.withUnsafeBytes {
                        cCharacteristics[characteristicIndex].uuid = .init(OpaquePointer($0.baseAddress))
                    }
                }
                // set handle
                characteristicHandles[characteristicIndex] = 0x0000
                characteristicHandles.withUnsafeBufferPointer {
                    cCharacteristics[characteristicIndex].val_handle = .init(mutating: $0.baseAddress?.advanced(by: characteristicIndex))
                }
            }
            cCharacteristics.withUnsafeBufferPointer {
                cServices[serviceIndex].characteristics = $0.baseAddress
            }
            characteristicsBuffers[serviceIndex] = cCharacteristics
            valueHandles[serviceIndex] = characteristicHandles
        }
        // queue service registration
        try ble_gatts_count_cfg(cServices).throwsError()
        try ble_gatts_add_svcs(cServices).throwsError()
        // register services
        try start()
        // store buffers
        cServices.removeLast() // nil terminator
        self.context.pointee.gattServer.servicesBuffer = cServices
        self.context.pointee.gattServer.characteristicsBuffers = characteristicsBuffers
        self.context.pointee.gattServer.buffers = buffers
        self.context.pointee.gattServer.services = services
        self.context.pointee.gattServer.characteristicValueHandles = valueHandles
        // get handles
        return valueHandles
    }
    
    /// Removes the service with the specified handle.
    public func remove(service: UInt16) {
        // iterate all services and find the specified handle
    }
    
    /// Clears the local GATT database.
    public func removeAllServices() {
        ble_gatts_reset()
        self.context.pointee.gattServer.services.removeAll(keepingCapacity: false)
        self.context.pointee.gattServer.buffers.removeAll(keepingCapacity: false)
        self.context.pointee.gattServer.services.removeAll(keepingCapacity: false)
        self.context.pointee.gattServer.characteristicsBuffers.removeAll(keepingCapacity: false)
        self.context.pointee.gattServer.characteristicValueHandles.removeAll(keepingCapacity: false)
    }
    
    public func dump() {
        ble_gatts_show_local()
    }
}

internal extension GATTServer.Context {
    
    func characteristic(for handle: UInt16) -> GATTAttribute<[UInt8]>.Characteristic? {
        for (serviceIndex, service) in services.enumerated() {
            for (characteristicIndex, characteristic) in service.characteristics.enumerated() {
                guard characteristicsBuffers[serviceIndex][characteristicIndex].val_handle.pointee == handle else {
                    continue
                }
                return characteristic
            }
        }
        return nil
    }
    
    mutating func didWriteCharacteristic(_ value: [UInt8], for handle: UInt16) -> Bool {
        for (serviceIndex, service) in services.enumerated() {
            for (characteristicIndex, _) in service.characteristics.enumerated() {
                guard characteristicsBuffers[serviceIndex][characteristicIndex].val_handle.pointee == handle else {
                    continue
                }
                services[serviceIndex].characteristics[characteristicIndex].value = value
                return true
            }
        }
        return false
    }
}

// typedef int ble_gatt_access_fn(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt *ctxt, void *arg);
internal func _ble_gatt_access(
    connectionHandle: UInt16,
    attributeHandle: UInt16,
    accessContext: UnsafeMutablePointer<ble_gatt_access_ctxt>?,
    context contextPointer: UnsafeMutableRawPointer?
) -> CInt {
    guard let context = contextPointer?.assumingMemoryBound(to: NimBLE.Context.self),
          let accessContext = accessContext else {
        return BLE_ATT_ERR_UNLIKELY
    }
    switch Int32(accessContext.pointee.op) {
    case BLE_GATT_ACCESS_OP_READ_CHR:
        // read characteristic
        guard let characteristic = context.pointee.gattServer.characteristic(for: attributeHandle) else {
            assertionFailure()
            return BLE_ATT_ERR_UNLIKELY
        }
        var memoryBuffer = MemoryBuffer(accessContext.pointee.om, retain: false)
        memoryBuffer.append(contentsOf: characteristic.value)
    case BLE_GATT_ACCESS_OP_WRITE_CHR:
        
        break
    default:
        break
    }
    return 0
}
