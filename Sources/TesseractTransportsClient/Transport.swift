//
//  Transport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
#if COCOAPODS
import TesseractShared
#else
import TesseractTransportsShared
#endif

public enum Status {
    case ready
    case unavailable(String)
    case error(TesseractError)
}

public protocol Connection: AnyObject {
    func send(request: Data) async -> Result<(), TesseractError>
    func receive() async -> Result<Data, TesseractError>
}

public protocol Transport: AnyObject {
    var id: String { get }
    func status(proto: String) async -> Status
    func connect(proto: String) -> Connection
}
