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

public protocol BoundTransport: AnyObject, CoreConvertible<ServiceBoundTransport> {}

public protocol Transport: AnyObject, CoreConvertible<ServiceTransport> {
    func bind(processor: TransportProcessor) -> any BoundTransport
}
