//
//  TestSigningService.swift
//  Extension
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import TesseractService

protocol TestSigningServiceDelegate: AnyObject {
    func acceptTx(tx: String) async -> Result<Bool, TesseractError>
}

class TestSigningService: TestService {
    var signature: String
    weak var delegate: TestSigningServiceDelegate?
    
    init(delegate: TestSigningServiceDelegate, signature: String) {
        self.delegate = delegate
        self.signature = signature
    }
    
    func signTransation(req: String) async -> Result<String, TesseractError> {
        guard let delegate = self.delegate else {
            return .failure(.null(reason: "TestSigningService delegate is empty"))
        }
        return await delegate.acceptTx(tx: req).flatMap {
            $0 ? .success(req + self.signature) : .failure(.cancelled)
        }
    }
}
