//
//  Transport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
import TesseractShared

public enum Status {
    case ready
    case unavailable(String)
    case error(CError)
}

public protocol Connection: AnyObject {
    func send(request: Data) async throws
    func receive() async throws -> Data
}

public protocol Transport: AnyObject {
    var id: String { get }
    func status(proto: String) async -> Status
    func connect(proto: String) -> Connection
}
