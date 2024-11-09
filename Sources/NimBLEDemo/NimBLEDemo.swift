//
//  NimBLEDemo.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import Bluetooth
import BluetoothGATT
import NimBLE

@main
struct NimBLEDemo {
    
    static func main() throws {
        let bluetooth = NimBLE()

        // get address
        let hostController = bluetooth.hostController
        let address = try hostController.address()
        print("Bluetooth Address:", address)
        
        let server = bluetooth.server
        let service = GATTAttribute.Service(
            uuid: .bit16(0x180A),
            primary: true,
            characteristics: []
        )
        try server.add(services: [service])
        server.dump()

        // Run event loop
        bluetooth.run()
    }
}
