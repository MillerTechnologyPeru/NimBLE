//
//  GATTServerTests.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/9/24.
//

import Testing
import Bluetooth
import BluetoothGATT
import CNimBLE
@testable import NimBLE

@MainActor
@Suite(.serialized)
struct GATTServerTests {
    
  @Test func addServices() throws {
      let bluetooth = NimBLE(initializePort: false)
      let server = bluetooth.server
      let service = GATTAttribute.Service(
        uuid: .bit16(0x180A),
        primary: true,
        characteristics: []
      )
      try server.add(services: [service])
      //try ble_gatts_start().throwsError()
      server.dump()
      
  }
}
