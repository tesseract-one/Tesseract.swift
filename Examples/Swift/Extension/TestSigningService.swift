//
//  TestSigningService.swift
//  Extension
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import TesseractService

protocol TestSigningServiceDelegate: AnyObject {
    func acceptTx(tx: String) async -> CResult<Bool>
}

class TestSigningService: TestService {
    var signature: String
    weak var delegate: TestSigningServiceDelegate?
    
    init(delegate: TestSigningServiceDelegate, signature: String) {
        self.delegate = delegate
        self.signature = signature
    }
    
    func signTransation(req: String) async -> CResult<String> {
        guard let delegate = self.delegate else {
            return .failure(.nullPtr)
        }
        return await delegate.acceptTx(tx: req).asyncFlatMap {
            $0 ? .success(req + self.signature) : .failure(.canceled)
        }
    }
}
