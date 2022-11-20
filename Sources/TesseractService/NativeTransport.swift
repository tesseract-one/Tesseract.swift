//
//  NativeTransport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 01.11.2022.
//

import Foundation
@_exported import TesseractUtils
import CTesseractService

public class NativeTransportProcessor: TransportProcessor {
    public private(set) var processor: CTesseractService.TransportProcessor
    
    public init(processor: CTesseractService.TransportProcessor) {
        self.processor = processor
    }
    
    deinit {
        transport_processor_free(&self.processor)
    }
    
    public func process(data: Data) async throws -> Data {
        let future = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            transport_processor_process(&self.processor, ptr.baseAddress, UInt(ptr.count))
        }
        return try await future.value
    }
}

extension Transport {
    public func asNative() -> CTesseractService.Transport {
        CTesseractService.Transport(
            ptr: .anyOwned(self),
            bind: transport_bind,
            release: transport_release
        )
    }
}

extension BoundTransport {
    public func asNative() -> CTesseractService.BoundTransport {
        CTesseractService.BoundTransport(
            ptr: .anyOwned(self),
            release: bound_transport_release
        )
    }
}

private func transport_bind(this: CTesseractService.Transport,
                            processor: CTesseractService.TransportProcessor) -> CTesseractService.BoundTransport
{
    var this = this
    let transport = this.ptr.anyOwned() as! Transport
    return transport
        .bind(processor: NativeTransportProcessor(processor: processor))
        .asNative()
}

private func transport_release(self: UnsafeMutablePointer<CTesseractService.Transport>!) {
    let _ = self.pointee.ptr.anyOwned()
}

private func bound_transport_release(self: UnsafeMutablePointer<CTesseractService.BoundTransport>!) {
    let _ = self.owned()
}

extension UnsafePointer where Pointee == CTesseractService.BoundTransport {
    public func unowned() -> BoundTransport {
        self.pointee.ptr.anyUnowned() as! BoundTransport
    }
}

extension UnsafeMutablePointer where Pointee == CTesseractService.BoundTransport {
    public func unowned() -> BoundTransport {
        self.pointee.ptr.anyUnowned() as! BoundTransport
    }
    
    public func owned() -> BoundTransport {
        self.pointee.ptr.anyOwned() as! BoundTransport
    }
}
