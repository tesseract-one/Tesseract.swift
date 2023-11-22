//
//  Tesseract.swift
//  
//
//  Created by Yehor Popovych on 26/09/2023.
//

import Foundation
import CTesseract
#if !COCOAPODS
@_exported import TesseractTransportsClient
#endif
@_exported import TesseractShared

// Class is not thread safe.
// Use mutex if you need multithreaded setup (but why?)
// Services and transports are thread safe
public final class Tesseract: TesseractBase {
    public private(set) var tesseract: ClientTesseract!
    
    public init(delegate: TesseractDelegate, serializer: Serializer = .default) throws {
        try super.init()
        tesseract = tesseract_client_new(delegate.toCore(), serializer.toCore())
    }
    
    public func service<S: Service>(_ service: S.Type) -> S {
        withUnsafePointer(to: &tesseract) { service.init(tesseract: $0) }
    }
    
    public func transport<T: CoreTransportConvertible>(_ transport: T) -> Self {
        tesseract = tesseract_client_add_transport(&tesseract, transport.toCore())
        return self
    }
    
    deinit {
        tesseract_client_free(&tesseract)
        tesseract = nil
    }
    
    public static func `default`(
        delegate: TesseractDelegate = SingleTransportDelegate(),
        serializer: Serializer = .default
    ) throws -> Self {
        #if os(iOS)
        try Self(
            delegate: delegate, serializer: serializer
        ).transport(IPCTransportIOS())
        #else
        try Self(
            delegate: delegate, serializer: serializer
        )
        #endif
    }
}
