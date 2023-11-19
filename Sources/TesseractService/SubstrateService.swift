//
//  SubstrateService.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

@_exported import enum TesseractShared.SubstrateAccountType
@_exported import struct TesseractShared.SubstrateGetAccountResponse

extension CTesseract.SubstrateService: CoreService {
    public func register(
        in tesseract: UnsafeMutablePointer<ServiceTesseract>
    ) -> ServiceTesseract {
        tesseract_service_add_substrate_service(tesseract, self)
    }
}

public protocol SubstrateServiceResult: TesseractShared.SubstrateServiceResult, Service
    where Core == CTesseract.SubstrateService {}

public protocol SubstrateService: SubstrateServiceResult, TesseractShared.SubstrateService {}

public extension SubstrateServiceResult {
    func toCore() -> Core {
        var value = Core(value: self)
        value.get_account = substrate_service_get_account
        value.sign_transaction = substrate_service_sign
        return value
    }
}

private func substrate_service_get_account(
    this: UnsafePointer<CTesseract.SubstrateService>!,
    accountType: CTesseract.SubstrateAccountType
) -> CFuture_SubstrateGetAccountResponse {
    CFuture_SubstrateGetAccountResponse {
        await this.unowned((any SubstrateServiceResult).self).castError().asyncFlatMap {
            await $0.getAccount(
                type: TesseractShared.SubstrateAccountType(cvalue: accountType)
            )
        }
    }
}

private func substrate_service_sign(
    this: UnsafePointer<CTesseract.SubstrateService>!,
    type: CTesseract.SubstrateAccountType, path: CStringRef!,
    extrinsic: CDataRef, metadata: CDataRef, types: CDataRef
) -> CFutureData {
    let path = path.copied()
    let extrinsic = extrinsic.copied()
    let metadata = metadata.copied()
    let types = types.copied()
    return CFutureData {
        await this.unowned((any SubstrateServiceResult).self).castError().asyncFlatMap {
            await $0.signTransation(type: TesseractShared.SubstrateAccountType(cvalue: type),
                                    path: path, extrinsic: extrinsic,
                                    metadata: metadata, types: types)
        }
    }
}
