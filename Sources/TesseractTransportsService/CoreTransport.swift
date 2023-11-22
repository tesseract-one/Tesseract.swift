//
//  CoreTransport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 01.11.2022.
//

import Foundation
import CTesseractShared
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

public protocol CoreTransportConvertible {
    func toCore() -> ServiceTransport
}

open class CoreTransportBase: CoreTransportConvertible {
    public private(set) var core: ServiceTransport!
    
    public init(
        initializer: (UnsafeMutablePointer<ServiceTransport>,
                      UnsafeMutablePointer<CTesseractShared.CError>) -> Bool
    ) throws {
        self.core = try CResult<ServiceTransport>
            .wrap(ccall: initializer)
            .castError(TesseractError.self)
            .get()
    }
    
    deinit {
        if core != nil { try! core.free().get() }
    }
    
    public func toCore() -> ServiceTransport {
        defer { core = nil }
        return core
    }
}

extension ServiceTransport: CSwiftAnyDropPtr {}

extension ServiceTransport {
    public init(transport: Transport) {
        self = ServiceTransport(value: transport)
        self.bind = transport_bind
    }
}

extension Transport {
    public func toCore() -> ServiceTransport {
        ServiceTransport(transport: self)
    }
}

extension BoundTransport {
    public func toCore() -> ServiceBoundTransport {
        ServiceBoundTransport(value: self)
    }
}

private func transport_bind(this: ServiceTransport,
                            processor: ServiceTransportProcessor) -> ServiceBoundTransport
{
    var this = this
    return try! this.owned(Transport.self).get()
        .bind(processor: TransportProcessor(processor: processor))
        .toCore()
}
