//
//  Transport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation

public protocol TransportProcessor {
    func process(data: Data) async throws -> Data
}

public protocol BoundTransport: AnyObject {}

public protocol Transport: AnyObject {
    func bind(processor: TransportProcessor) -> BoundTransport
}
