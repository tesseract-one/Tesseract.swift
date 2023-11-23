//
//  Transport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
import CTesseractShared
#if COCOAPODS
import TesseractShared
#else
import TesseractTransportsShared
#endif

public enum Status {
    case ready
    case unavailable(String)
    case error(TesseractError)
    
    public var isReady: Bool {
        switch self {
        case .ready: return true
        default: return false
        }
    }
}

public protocol Connection: AnyObject, CoreConvertible<ClientConnection> {
    func send(request: Data) async -> Result<(), TesseractError>
    func receive() async -> Result<Data, TesseractError>
}

public protocol Transport: AnyObject, CoreConvertible<ClientTransport> {
    var id: String { get }
    func status(proto: String) async -> Status
    func connect(proto: String) -> any Connection
}
