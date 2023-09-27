//
//  Transport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
import TesseractShared

public protocol TransportProcessor: AnyObject {
    func process(data: Data) async -> Result<Data, CError>
}

public protocol BoundTransport: AnyObject {}

public protocol Transport: AnyObject {
    func bind(processor: TransportProcessor) -> BoundTransport
}
