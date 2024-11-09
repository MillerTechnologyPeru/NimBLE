//
//  HostController.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import Bluetooth
import BluetoothGAP
import BluetoothHCI
import CNimBLE

public extension NimBLE {
    
    var hostController: HostController { HostController(context: context) }
}

public struct HostController {
    
    internal let context: UnsafeMutablePointer<NimBLE.Context>
    
    public var isEnabled: Bool {
        ble_hs_is_enabled() == 1
    }
    
    public func address(
        type: LowEnergyAddressType = .public
    ) throws(NimBLEError) -> BluetoothAddress {
        var address = BluetoothAddress.zero
        try withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 6) {
                ble_hs_id_copy_addr(type.rawValue, $0, nil)
            }
        }.throwsError()
        return address
    }
}
