//
//  Hexadecimal.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/23/24.
//


internal extension FixedWidthInteger {
    
    func toHexadecimal() -> String {
        let length = MemoryLayout<Self>.size * 2
        var string: String
        string = String(self, radix: 16, uppercase: true)
        // Add Zero padding
        while string.utf8.count < length {
            string = "0" + string
        }
        assert(string.utf8.count == length)
        #if !hasFeature(Embedded)
        assert(string == string.uppercased(), "String should be uppercased")
        #endif
        return string
    }
}
