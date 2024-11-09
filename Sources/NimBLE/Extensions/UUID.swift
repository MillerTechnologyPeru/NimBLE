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
    
    init(_ string: String) throws(NimBLEError) {
        self.init()
        try withUnsafeMutablePointer(to: &self) { uuidBuffer in
            string.withCString { cString in
                ble_uuid_from_str(uuidBuffer, cString)
            }
        }.throwsError()
    }
    
    init?<C>(data: C) where C: Collection, C.Element == UInt8 {
        guard let value = data.withContiguousStorageIfAvailable({
            $0.withUnsafeBytes {
                try? ble_uuid_any_t(buffer: $0)
            }
        }), let unwrapped = value else { return nil }
        self = unwrapped
    }
    
    init(buffer: UnsafeRawBufferPointer) throws(NimBLEError) {
        self.init()
        try ble_uuid_init_from_buf(
            &self,
            buffer.baseAddress,
            buffer.count
        ).throwsError()
    }
    
    init(_ pointer: UnsafePointer<ble_uuid_t>) {
        self.init()
        ble_uuid_copy(&self, pointer)
    }
}

extension ble_uuid_any_t: @retroactive CustomStringConvertible {
    
    public var description: String {
        withUnsafeBytes(of: self) { uuidBuffer in
            var cString = [CChar](repeating: 0, count: 37)
            ble_uuid_to_str(
                uuidBuffer.assumingMemoryBound(to: ble_uuid_t.self).baseAddress,
                &cString
            )
            return String(cString: &cString)
        }
    }
}

extension ble_uuid_any_t: @retroactive Equatable {
    
    public static func == (lhs: ble_uuid_any_t, rhs: ble_uuid_any_t) -> Bool {
        withUnsafeBytes(of: lhs) {
            $0.withMemoryRebound(to: ble_uuid_t.self) { lhsPointer in
                withUnsafeBytes(of: rhs) {
                    $0.withMemoryRebound(to: ble_uuid_t.self) { rhsPointer in
                        ble_uuid_cmp(lhsPointer.baseAddress, rhsPointer.baseAddress) == 0
                    }
                }
            }
        }
    }
}

extension ble_uuid_any_t { //: @retroactive DataConvertible {
    
    public var dataLength: Int {
        let value = withUnsafeBytes(of: self) {
            $0.withMemoryRebound(to: ble_uuid_t.self) {
                ble_uuid_length($0.baseAddress)
            }
        }
        return Int(value)
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

