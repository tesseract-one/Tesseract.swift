//
//  SubstrateService.swift
//  
//
//  Created by Yehor Popovych on 21/11/2023.
//

import Foundation
import CTesseract
import TesseractShared

public final class SubstrateService: ServiceBase<CTesseract.SubstrateService>,
                                     TesseractShared.SubstrateService
{
    public func getAccount(
        type: TesseractShared.SubstrateAccountType
    ) async throws -> TesseractShared.SubstrateGetAccountResponse {
        try await withUnsafePointer(to: &service) {
            $0.pointee.get_account($0, type.asCValue)
        }.result.castError(TesseractError.self).get()
    }
    
    public func signTransaction(
        type: TesseractShared.SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async throws -> Data {
        try await extrinsic.withPtrRef { ext in
            metadata.withPtrRef { meta in
                types.withPtrRef { types in
                    withUnsafePointer(to: &service) {
                        $0.pointee.sign_transaction($0, type.asCValue, path, ext, meta, types)
                    }
                }
            }
        }.result.castError(TesseractError.self).get()
    }
}

extension CTesseract.SubstrateService: CoreService {
    public static func get(from tesseract: UnsafePointer<ClientTesseract>) -> Self {
        tesseract_client_get_substrate_service(tesseract)
    }
}
