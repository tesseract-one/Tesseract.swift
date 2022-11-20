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

extension CTesseractService.Transport: CSwiftAnyPtr {}

extension CTesseractService.Transport {
    public init(transport: Transport) {
        self = CTesseractService.Transport(owned: transport)
        self.bind = transport_bind
        self.release = transport_release
    }
}

extension Transport {
    public func asNative() -> CTesseractService.Transport {
        CTesseractService.Transport(transport: self)
    }
}

extension CTesseractService.BoundTransport: CSwiftAnyPtr {}

extension CTesseractService.BoundTransport {
    public init(transport: BoundTransport) {
        self = CTesseractService.BoundTransport(owned: transport)
        self.release = bound_transport_release
    }
}

extension BoundTransport {
    public func asNative() -> CTesseractService.BoundTransport {
        CTesseractService.BoundTransport(transport: self)
    }
}

private func transport_bind(this: CTesseractService.Transport,
                            processor: CTesseractService.TransportProcessor) -> CTesseractService.BoundTransport
{
    var this = this
    return (this.owned() as! Transport)
        .bind(processor: NativeTransportProcessor(processor: processor))
        .asNative()
}

private func transport_release(self: UnsafeMutablePointer<CTesseractService.Transport>!) {
    let _ = self.owned()
}

private func bound_transport_release(self: UnsafeMutablePointer<CTesseractService.BoundTransport>!) {
    let _ = self.owned()
}
