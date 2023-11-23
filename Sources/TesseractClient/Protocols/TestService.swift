//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 21/11/2023.
//

import Foundation
import CTesseract
import TesseractShared

public final class TestService: ServiceBase<CTesseract.TestService>,
                                TesseractShared.TestService
{
    public func signTransaction(req: String) async throws -> String {
        try await service.sign_transaction(&service, req)
            .result
            .castError(TesseractError.self).get()
    }
}

extension CTesseract.TestService: CoreService {
    public static func get(from tesseract: UnsafePointer<ClientTesseract>) -> Self {
        tesseract_client_get_test_service(tesseract)
    }
}
