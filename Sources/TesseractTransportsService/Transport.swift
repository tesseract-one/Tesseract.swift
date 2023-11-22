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

public protocol BoundTransport: AnyObject {}

public protocol Transport: CoreTransportConvertible, AnyObject {
    func bind(processor: TransportProcessor) -> BoundTransport
}
