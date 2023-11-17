//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 07/11/2023.
//

import Foundation
#if !COCOAPODS
import TesseractTransportsShared
#endif

public protocol TestServiceResult {
    func signTransation(req: String) async -> Result<String, TesseractError>
}

public protocol TestService: TestServiceResult {
    func signTransation(req: String) async throws -> String
}

public extension TestService {
    func signTransation(req: String) async -> Result<String, TesseractError> {
        await Result { try await signTransation(req: req) }
    }
}
