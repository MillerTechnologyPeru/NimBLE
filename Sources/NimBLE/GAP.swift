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

/// NimBLE GAP interface.
public struct GAP: ~Copyable {
    
    private(set) var advertisementData = LowEnergyAdvertisingData()
    
    private(set) var scanResponse = LowEnergyAdvertisingData()
    
    /// Indicates whether an advertisement procedure is currently in progress.
    public var isAdvertising: Bool {
        ble_gap_adv_active() == 1
    }
    
    /// Start advertising
    public func startAdvertising(
        addressType: LowEnergyAddressType = .public,
        address: BluetoothAddress? = nil,
        parameters: ble_gap_adv_params = ble_gap_adv_params(conn_mode: UInt8(BLE_GAP_CONN_MODE_NON), disc_mode: UInt8(BLE_GAP_DISC_MODE_GEN), itvl_min: 0, itvl_max: 0, channel_map: 0, filter_policy: 0, high_duty_cycle: 0)
    ) throws(NimBLEError) {
        var address = ble_addr_t(
            type: 0,
            val: (address ?? .zero).bytes
        )
        var parameters = parameters
        try ble_gap_adv_start(addressType.rawValue, &address, BLE_HS_FOREVER, &parameters, _gap_callback, nil).throwsError()
    }
    
    /// Stops the currently-active advertising procedure. 
    public func stopAdvertising() throws(NimBLEError) {
        try ble_gap_adv_stop().throwsError()
    }
    
    /// Configures the data to include in subsequent advertisements.
    public mutating func setAdvertisement(_ data: LowEnergyAdvertisingData) throws(NimBLEError) {
        advertisementData = data
        try advertisementData.withUnsafePointer {
            ble_gap_adv_set_data($0, Int32(data.length))
        }.throwsError()
    }
    
    /// Configures the data to include in subsequent scan responses.
    public mutating func setScanResponse(_ data: LowEnergyAdvertisingData) throws(NimBLEError) {
        scanResponse = data
        try scanResponse.withUnsafePointer {
            ble_gap_adv_rsp_set_data($0, Int32(data.length))
        }.throwsError()
    }
}

internal func _gap_callback(event: UnsafeMutablePointer<ble_gap_event>?, context: UnsafeMutableRawPointer?) -> Int32 {
    return 0
}
