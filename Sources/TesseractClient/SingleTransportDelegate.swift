//
//  SingleTransportDelegate.swift
//  
//
//  Created by Yehor Popovych on 21/11/2023.
//

import Foundation
#if !COCOAPODS
@_exported import TesseractTransportsClient
#endif

public final class SingleTransportDelegate: TesseractDelegate {
    public init() {}
    
    public func select(transports: Dictionary<String, Status>) async -> String? {
        let active = transports.filter { $0.value.isReady }
        assert(active.count <= 1, "More than one active transport")
        return active.first?.key
    }
}
