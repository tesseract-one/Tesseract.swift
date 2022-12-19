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
            transport_processor_process(self.processor, ptr.baseAddress, UInt(ptr.count))
        }
        return try await future.value
    }
}

extension CTesseractService.Transport: CSwiftAnyDropPtr {}

extension CTesseractService.Transport {
    public init(transport: Transport) {
        self = CTesseractService.Transport(value: transport)
        self.bind = transport_bind
    }
}

extension Transport {
    public func asNative() -> CTesseractService.Transport {
        CTesseractService.Transport(transport: self)
    }
}

extension BoundTransport {
    public func asNative() -> CTesseractService.BoundTransport {
        CTesseractService.BoundTransport(value: self)
    }
}

private func transport_bind(this: CTesseractService.Transport,
                            processor: CTesseractService.TransportProcessor) -> CTesseractService.BoundTransport
{
    var this = this
    return (try! this.owned() as! Transport)
        .bind(processor: NativeTransportProcessor(processor: processor))
        .asNative()
}
