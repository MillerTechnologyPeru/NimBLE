//
//  NimBLEDemo.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/8/24.
//

import Bluetooth
import NimBLE

@main
struct NimBLEDemo {
    
    static func main() throws {
        var bluetooth = NimBLE()
        let address = try bluetooth.address()
        print("Bluetooth Address:", address)
        
        // Run event loop
        bluetooth.run()
    }
}
