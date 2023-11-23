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

public typealias CoreTransport = AutoFree<ServiceTransport> & CoreConvertible<ServiceTransport>

public extension AutoFree where Ptr == ServiceTransport {
    func toCore() -> ServiceTransport { take() }
}

extension ServiceTransport: CAnyObjectPtr {}

extension ServiceTransport {
    public init(transport: any Transport) {
        self = ServiceTransport(value: transport)
        self.bind = transport_bind
    }
}

public extension Transport {
    func toCore() -> ServiceTransport {
        ServiceTransport(transport: self)
    }
}

public extension BoundTransport {
    func toCore() -> ServiceBoundTransport {
        ServiceBoundTransport(value: self)
    }
}

private func transport_bind(this: ServiceTransport,
                            processor: ServiceTransportProcessor) -> ServiceBoundTransport
{
    var this = this
    return try! this.owned((any Transport).self).get()
        .bind(processor: TransportProcessor(processor: processor))
        .toCore()
}
