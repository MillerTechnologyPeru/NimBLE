//
//  UUID.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/6/24.
//

import Bluetooth
import CNimBLE

internal extension ble_uuid_any_t {
    
    init(_ uuid: BluetoothUUID) {
        switch uuid {
        case .bit16(let value):
            self.init(u16: .init(uuid: value))
        case .bit32(let value):
            self.init(u32: .init(uuid: value))
        case .bit128(let value):
            self.init(u128: .init(uuid: value))
        }
    }
}

internal extension ble_uuid16_t {
    
    init(uuid: UInt16) {
        self.init(u: .init(type: UInt8(BLE_UUID_TYPE_16)), value: uuid)
    }
}

internal extension ble_uuid32_t {
    
    init(uuid: UInt32) {
        self.init(u: .init(type: UInt8(BLE_UUID_TYPE_32)), value: uuid)
    }
}

internal extension ble_uuid128_t {
    
    init(uuid: UInt128) {
        self.init(u: .init(type: UInt8(BLE_UUID_TYPE_128)), value: uuid.bytes)
    }
}
