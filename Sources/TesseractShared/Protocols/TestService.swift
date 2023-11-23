//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 07/11/2023.
//

import Foundation
import CTesseract
#if !COCOAPODS
import TesseractTransportsShared
#endif

public extension BlockchainProtocol {
    static let test = BlockchainProtocol(ptr: tesseract_protocol_test_new())
}

public protocol TestServiceResult: Service {
    func signTransactionRes(req: String) async -> Result<String, TesseractError>
}

public protocol TestService: TestServiceResult {
    func signTransaction(req: String) async throws -> String
}

public extension TestServiceResult {
    var proto: BlockchainProtocol { .test }
}

public extension TestService {
    func signTransactionRes(req: String) async -> Result<String, TesseractError> {
        await Result { try await signTransaction(req: req) }
    }
}

extension CTesseract.TestService: CAnyObjectPtr {}
