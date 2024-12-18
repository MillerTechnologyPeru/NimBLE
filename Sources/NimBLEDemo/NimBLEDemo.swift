//
//  NimBLEDemo.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import Foundation
import Bluetooth
import BluetoothGATT
import NimBLE
import CNimBLE

@main
struct NimBLEDemo {
    
    static func main() throws {
        let bluetooth = NimBLE()

        // get address
        let hostController = bluetooth.hostController
        while hostController.isEnabled == false {
            Thread.sleep(forTimeInterval: 1.0)
        }
        
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
        server.dump()
        
        let address = try hostController.address()
        print("Bluetooth Address:", address)

        // Run event loop
        bluetooth.run()
    }
}
