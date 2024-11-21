//
//  GATTServerTests.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/9/24.
//

import Foundation
import Testing
import Bluetooth
import BluetoothGATT
import CNimBLE
@testable import NimBLE

@MainActor
@Suite(.serialized)
struct GATTServerTests {
    
  @Test func addServices() throws {
      let bluetooth = NimBLE()
      let server = bluetooth.server
      let service = GATTAttribute<[UInt8]>.Service(
        uuid: .bit16(0x180A),
        isPrimary: true,
        characteristics: [
            .init(
                uuid: .manufacturerNameString,
                value: Array("Test Inc.".utf8),
                permissions: [.read],
                properties: [.read],
                descriptors: [
                    .init(GATTUserDescription(rawValue: "Manufacturer Name String"), permissions: .read)
                ]
            )
        ]
      )
      try server.set(services: [service])
      defer {
          server.removeAllServices()
      }
      server.dump()
      
  }
}
