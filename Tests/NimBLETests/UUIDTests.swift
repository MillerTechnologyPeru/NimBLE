//
//  UUIDTests.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import Testing
import Bluetooth
import CNimBLE
@testable import NimBLE

@Suite struct UUIDTests {
    
  @Test func bit16() throws {
      let integer: UInt16 = 0x180A
      let uuid = BluetoothUUID.bit16(integer)
      let nimbleValue = ble_uuid_any_t(u16: ble_uuid16_t(uuid: integer))
      #expect(nimbleValue == ble_uuid_any_t(uuid))
      #expect(nimbleValue.u16.value == integer)
      #expect("0x" + uuid.rawValue.lowercased() == nimbleValue.description)
      #expect(try ble_uuid_any_t(uuid.rawValue).description == nimbleValue.description)
      #expect(nimbleValue.dataLength == 2)
  }
}
