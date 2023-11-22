//
//  Data.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractShared

extension CDataRef: CType {}
extension CData: CType {}

extension CDataRef: CPtrRef {
    public typealias SVal = Data
    
    public func copied() -> SVal {
        Data(bytes: self.ptr, count: Int(self.len))
    }
}

extension CData: CPtr {
    public typealias SVal = Data
    
    public func copied() -> SVal {
        Data(bytes: self.ptr, count: Int(self.len))
    }
    
    public mutating func owned() -> SVal {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_data_free(&self)
        self.ptr = nil
    }
}

public extension CDataRef {
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
    
    init(buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
}

public extension CData {
    init(buffer: UnsafeBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
    
    init(buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
}

extension Data: AsCRef {
    public typealias Ref = (UnsafePointer<UInt8>, UInt)
    
    public func withRef<T>(_ fn: (Ref) throws -> T) rethrows -> T {
        try withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let bytesPtr = ptr.bindMemory(to: UInt8.self)
            return try fn((bytesPtr.baseAddress!, UInt(bytesPtr.count)))
        }
    }
}

extension Data: AsCPtrRef {
    public typealias RefPtr = CDataRef

    public func withPtrRef<T>(_ fn: (RefPtr) throws -> T) rethrows -> T {
        try self.withUnsafeBytes { ptr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self)
            let cdata = CDataRef(
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
        try! withPtrRef { cdata in
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
