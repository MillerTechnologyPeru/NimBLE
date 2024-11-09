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

/// NimBLE GATT Server interface.
public struct GATTServer: ~Copyable {
    
    // MARK: - Properties
    
    public var gap: GAP
    /*
    /// Callback to handle GATT read requests.
    public var willRead: ((GATTReadRequest<Central>) -> ATTError?)?
    
    /// Callback to handle GATT write requests.
    public var willWrite: ((GATTWriteRequest<Central>) -> ATTError?)?
    
    /// Callback to handle post-write actions for GATT write requests.
    public var didWrite: ((GATTWriteConfirmation<Central>) -> ())?
    */
    /// A Boolean value that indicates whether the peripheral is advertising data.
    public var isAdvertising: Bool {
        gap.isAdvertising
    }
    
    // MARK: - Initialization
    
    public init(gap: consuming GAP) {
        self.gap = gap
        //ble_svc_gap_init()
        //ble_svc_gatt_init()
    }
    
    // MARK: - Methods
    
    /// Start advertising the peripheral and listening for incoming connections.
    public mutating func start() throws(NimBLEError) {
        let parameters = ble_gap_adv_params(conn_mode: UInt8(BLE_GAP_CONN_MODE_UND), disc_mode: UInt8(BLE_GAP_DISC_MODE_GEN), itvl_min: 0, itvl_max: 0, channel_map: 0, filter_policy: 0, high_duty_cycle: 0)
        try gap.startAdvertising(parameters: parameters)
    }
    
    /// Stop the peripheral.
    public mutating func stop() {
        try? gap.stopAdvertising()
    }
    
    /// Attempts to add the specified service to the GATT database.
    ///
    /// - Returns: Handle for service declaration and handles for characteristic value handles.
    public mutating func add(service: GATTAttribute.Service) throws(NimBLEError) {
        try add(services: [service])
    }
    
    public mutating func add(services: [GATTAttribute.Service]) throws(NimBLEError) {
        var cServices = UnsafeMutablePointer<ble_gatt_svc_def>.allocate(capacity: services.count + 1)
        // TODO: Free memory
        for (serviceIndex, service) in services.enumerated() {
            cServices[serviceIndex].type = service.primary ? UInt8(BLE_GATT_SVC_TYPE_PRIMARY) : UInt8(BLE_GATT_SVC_TYPE_SECONDARY)
            var uuidPointer = UnsafeMutablePointer<ble_uuid16_t>.allocate(capacity: 1)
            // TODO: Free memory
            uuidPointer.pointee = ble_uuid16_t(uuid: 0x001)
            cServices[serviceIndex].uuid = .init(OpaquePointer(uuidPointer))
        }
        try ble_gatts_add_svcs(cServices).throwsError()
        
    }
    
    /// Removes the service with the specified handle.
    public mutating func remove(service: UInt16) {
        // iterate all services and find the specified handle
    }
    
    /// Clears the local GATT database.
    public mutating func removeAllServices() {
        ble_gatts_reset()
    }
    
    public func dump() {
        ble_gatts_show_local()
    }
}
