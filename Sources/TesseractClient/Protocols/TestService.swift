//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 21/11/2023.
//

import Foundation
import CTesseract
import TesseractShared

public final class TestService: Service, TesseractShared.TestService {
    public private(set) var service: CTesseract.TestService
    
    public init(tesseract: UnsafePointer<ClientTesseract>) {
        service = tesseract_client_get_test_service(tesseract)
    }
    
    public func signTransaction(req: String) async throws -> String {
        try await withUnsafePointer(to: &service) {
            $0.pointee.sign_transaction($0, req)
        }.result.castError(TesseractError.self).get()
    }
    
    deinit {
        try! service.free().get()
    }
}
