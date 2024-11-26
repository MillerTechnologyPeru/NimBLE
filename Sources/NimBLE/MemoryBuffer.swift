//
//  MemoryBuffer.swift
//  NimBLE
//
//  Created by Alsey Coleman Miller on 11/20/24.
//

import CNimBLE

/// NimBLE Memory Buffer
public struct MemoryBuffer: ~Copyable {
    
    var pointer: UnsafeMutablePointer<os_mbuf>
    
    let retain: Bool
    
    public init(_ other: borrowing MemoryBuffer) {
        guard let pointer = os_mbuf_dup(other.pointer) else {
            fatalError("Unable to duplicate buffer")
        }
        self.init(pointer, retain: true)
    }
    
    public init?(pool: borrowing MemoryBuffer.Pool, capacity: UInt16) {
        guard let pointer = os_mbuf_get(pool.pointer, capacity) else {
            return nil
        }
        self.init(pointer, retain: true)
    }
    
    init(_ pointer: UnsafeMutablePointer<os_mbuf>, retain: Bool) {
        self.pointer = pointer
        self.retain = retain
    }
    
    deinit {
        if retain {
            os_mbuf_free(pointer)
        }
    }
    
    public mutating func append(_ pointer: UnsafeRawPointer, count: UInt16) throws(NimBLEError) {
        try os_mbuf_append(self.pointer, pointer, count).throwsError()
    }
    
    public mutating func append(_ pointer: UnsafePointer<UInt8>, count: Int) {
        do { try append(UnsafeRawPointer(pointer), count: UInt16(count)) }
        catch {
            fatalError("Unable to append to buffer")
        }
    }
    
    public mutating func append <C: Collection> (contentsOf bytes: C) where C.Element == UInt8 {
        guard bytes.isEmpty == false else {
            return
        }
        bytes.withContiguousStorageIfAvailable {
            append($0.baseAddress!, count: $0.count)
        }
    }
    
    public var count: Int {
        Int(os_mbuf_len(self.pointer))
    }
}

public extension [UInt8] {
    
    init(_ memoryBuffer: borrowing MemoryBuffer) throws(NimBLEError) {
        let length = memoryBuffer.count
        guard length > 0 else {
            self.init()
            return
        }
        var outLength: UInt16 = 0
        self.init(repeating: 0, count: length)
        try self.withUnsafeMutableBytes {
            ble_hs_mbuf_to_flat(memoryBuffer.pointer, $0.baseAddress, UInt16(length), &outLength)
        }.throwsError()
        assert(outLength == length)
        assert(self.count == length)
    }
}

public extension MemoryBuffer {
    
    struct Pool: ~Copyable {
        
        var pointer: UnsafeMutablePointer<os_mbuf_pool>
        
        init(_ pointer: UnsafeMutablePointer<os_mbuf_pool>) {
            self.pointer = pointer
        }
    }
}
