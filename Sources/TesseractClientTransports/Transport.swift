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
    func send(request: Data) async -> Result<(), CError>
    func receive() async -> Result<Data, CError>
}

public protocol Transport: AnyObject {
    var id: String { get }
    func status(proto: String) async -> Status
    func connect(proto: String) -> Connection
}
