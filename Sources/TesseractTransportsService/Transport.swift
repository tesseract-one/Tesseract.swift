//
//  Transport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
import CTesseractShared
#if COCOAPODS
import TesseractShared
#else
import TesseractTransportsShared
#endif

public protocol BoundTransport: CoreConvertible<ServiceBoundTransport>, AnyObject {}

public protocol Transport: CoreConvertible<ServiceTransport>, AnyObject {
    func bind(processor: TransportProcessor) -> any BoundTransport
}
