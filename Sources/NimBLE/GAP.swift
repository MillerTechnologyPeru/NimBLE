//
//  GAP.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import Bluetooth
import BluetoothGAP
import BluetoothHCI
import CNimBLE

public extension NimBLE {
    
    var gap: GAP {
        GAP(context: context)
    }
}

/// NimBLE GAP interface.
public struct GAP {
    
    internal struct Context {
                
        var advertisment = LowEnergyAdvertisingData()
        
        var scanResponse = LowEnergyAdvertisingData()
    }
    
    internal let context: UnsafeMutablePointer<NimBLE.Context>
    
    /// Indicates whether an advertisement procedure is currently in progress.
    public var isAdvertising: Bool {
        ble_gap_adv_active() == 1
    }
    
    /// Start advertising
    public func startAdvertising(
        addressType: LowEnergyAddressType = .public,
        address: BluetoothAddress? = nil,
        parameters: ble_gap_adv_params = ble_gap_adv_params(conn_mode: UInt8(BLE_GAP_CONN_MODE_UND), disc_mode: UInt8(BLE_GAP_DISC_MODE_GEN), itvl_min: 0, itvl_max: 0, channel_map: 0, filter_policy: 0, high_duty_cycle: 0)
    ) throws(NimBLEError) {
        var address = ble_addr_t(
            type: 0,
            val: (address ?? .zero).bytes
        )
        var parameters = parameters
        try ble_gap_adv_start(addressType.rawValue, &address, BLE_HS_FOREVER, &parameters, _gap_callback, context).throwsError()
    }
    
    /// Stops the currently-active advertising procedure. 
    public func stopAdvertising() throws(NimBLEError) {
        try ble_gap_adv_stop().throwsError()
    }
    
    public var advertisementData: LowEnergyAdvertisingData {
        context.pointee.gap.advertisment
    }
    
    /// Configures the data to include in subsequent advertisements.
    public func setAdvertisement(_ data: LowEnergyAdvertisingData) throws(NimBLEError) {
        context.pointee.gap.advertisment = data
        try context.pointee.gap.advertisment.withUnsafePointer {
            ble_gap_adv_set_data($0, Int32(data.length))
        }.throwsError()
    }
    
    public var scanResponse: LowEnergyAdvertisingData {
        context.pointee.gap.scanResponse
    }
    
    /// Configures the data to include in subsequent scan responses.
    public func setScanResponse(_ data: LowEnergyAdvertisingData) throws(NimBLEError) {
        context.pointee.gap.scanResponse = data
        try context.pointee.gap.scanResponse.withUnsafePointer {
            ble_gap_adv_rsp_set_data($0, Int32(data.length))
        }.throwsError()
    }
}

internal func _gap_callback(event: UnsafeMutablePointer<ble_gap_event>?, context contextPointer: UnsafeMutableRawPointer?) -> Int32 {
    guard let context = contextPointer?.assumingMemoryBound(to: NimBLE.Context.self),
        let event else {
        return 0
    }
    let log = context.pointee.log
    switch Int32(event.pointee.type) {
    case BLE_GAP_EVENT_CONNECT:
        let handle = event.pointee.connect.conn_handle
        log?("Connected - Handle \(handle)")
    case BLE_GAP_EVENT_DISCONNECT:
        let handle = event.pointee.connect.conn_handle
        log?("Disconnected - Handle \(handle)")
        // resume advertising
        do {
            try GAP(context: context).startAdvertising()
        }
        catch {
            log?("Unable to advertise")
        }
    default:
        break
    }
    
    return 0
}
