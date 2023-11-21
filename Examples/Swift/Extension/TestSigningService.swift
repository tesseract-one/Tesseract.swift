//
//  TestSigningService.swift
//  Extension
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import TesseractService

protocol TestSigningServiceDelegate: AnyObject {
    func acceptTx(tx: String) async throws -> Bool
}

class TestSigningService: TestService {    
    var signature: String
    weak var delegate: TestSigningServiceDelegate?
    
    init(delegate: TestSigningServiceDelegate, signature: String) {
        self.delegate = delegate
        self.signature = signature
    }
    
    func signTransaction(req: String) async throws -> String {
        guard let delegate = self.delegate else {
            throw TesseractError.null(TestSigningService.self)
        }
        guard try await delegate.acceptTx(tx: req) else {
            throw TesseractError.cancelled
        }
        return req + signature
    }
}
