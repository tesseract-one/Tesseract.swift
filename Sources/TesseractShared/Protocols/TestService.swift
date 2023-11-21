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

public protocol TestServiceResult {
    func signTransaction(req: String) async -> Result<String, TesseractError>
}

public protocol TestService: TestServiceResult {
    func signTransaction(req: String) async throws -> String
}

public extension TestService {
    func signTransaction(req: String) async -> Result<String, TesseractError> {
        await Result { try await signTransaction(req: req) }
    }
}

extension CTesseract.TestService: CSwiftAnyDropPtr {}
