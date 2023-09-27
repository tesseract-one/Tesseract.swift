//
//  Data.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseract

extension CData: CType {}

extension CData: CPtr {
    public typealias Val = Data
    
    public func copied() -> Data {
        Data(bytes: self.ptr, count: Int(self.len))
    }
    
    public mutating func owned() -> Data {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_data_free(&self)
        self.ptr = nil
    }
}

extension CData {
    public init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
    
    public init(buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
}

extension Data: AsCRef {
    public typealias Ref = UnsafePointer<CData>
    
    public func withRef<T>(_ fn: @escaping (Ref) throws -> T) rethrows -> T {
        try withPtrRef { ptr in
            var ptr = ptr
            return try fn(&ptr)
        }
    }
}

extension Data: AsCPtrRef {
    public typealias RefPtr = CData
    
    public func withPtrRef<T>(_ fn: @escaping (RefPtr) throws -> T) rethrows -> T {
        try self.withUnsafeBytes { ptr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self)
            let cdata = CData(
                ptr: bytesPtr.baseAddress,
                len: UInt(bytesPtr.count)
            )
            return try fn(cdata)
        }
    }
}

extension Data: AsCPtrCopy {
    public typealias CopyPtr = CData
    
    public func copiedPtr() -> CData {
        try! withRef { cdata in
            try CResult<CData>.wrap { res, err in
                tesseract_utils_data_clone(cdata, res, err)
            }.get()
        }
    }
}

extension UnsafeBufferPointer where Element == UInt8 {
    public var cData: CData {
        CData(buffer: self)
    }
}

extension UnsafeMutableBufferPointer where Element == UInt8 {
    public var cData: CData {
        CData(buffer: self)
    }
}

