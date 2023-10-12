//
//  Transport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
#if COCOAPODS
import TesseractShared
#else
import TesseractTransportsShared
#endif

public protocol TransportProcessor: AnyObject {
    func process(data: Data) async -> Result<Data, TesseractError>
}

public protocol BoundTransport: AnyObject {}

public protocol Transport: AnyObject {
    func bind(processor: TransportProcessor) -> BoundTransport
}
