//
//  SubstrateService.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseractBin
import TesseractShared

extension SubstrateGetAccountResponse: CValue, CType {
    public typealias CVal = Self
}

extension CFuture_SubstrateGetAccountResponse: CFuturePtr {
    public typealias CVal = SubstrateGetAccountResponse
    public typealias Val = (pubKey: Data, path: String)
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) -> CResult<CVal>? {
        _withOnCompleteContext(cb) { ctx, value, error in
            self.set_on_complete(&self, ctx, value, error) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, value, error, cb in
            Self._setOnCompleteFunc(this, ctx, value, error) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public static func convert(
        cvalue: inout SubstrateGetAccountResponse
    ) -> CResult<(pubKey: Data, path: String)> {
        .success((pubKey: cvalue.public_key.owned(), path: cvalue.path.owned()))
    }
    
    public static func convert(
        value: inout (pubKey: Data, path: String)
    ) -> CResult<SubstrateGetAccountResponse> {
        .success(SubstrateGetAccountResponse(public_key: value.pubKey.copiedPtr(),
                                             path: value.path.copiedPtr()))
    }
}

extension CTesseract.SubstrateService: CoreService {
    public func register(
        in tesseract: UnsafeMutablePointer<ServiceTesseract>
    ) -> ServiceTesseract {
        tesseract_service_add_substrate_service(tesseract, self)
    }
}

public protocol SubstrateService: Service where Core == CTesseract.SubstrateService {
    func getAccount(
        type: SubstrateAccountType
    ) async -> Result<(pubKey: Data, path: String), TesseractError>
    
    func signTransation(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async -> Result<Data, TesseractError>
}

public extension SubstrateService {
    func toCore() -> Core {
        var value = Core(value: self)
        value.get_account = substrate_service_get_account
        value.sign_transaction = substrate_service_sign
        return value
    }
}

private func substrate_service_get_account(
    this: UnsafePointer<CTesseract.SubstrateService>!,
    accountType: SubstrateAccountType
) -> CFuture_SubstrateGetAccountResponse {
    CFuture_SubstrateGetAccountResponse {
        await this.unowned((any SubstrateService).self).castError().asyncFlatMap {
            await $0.getAccount(type: accountType)
        }
    }
}

private func substrate_service_sign(
    this: UnsafePointer<CTesseract.SubstrateService>!,
    type: SubstrateAccountType, path: CStringRef!,
    extrinsic: CDataRef, metadata: CDataRef, types: CDataRef
) -> CFutureData {
    let path = path.copied()
    let extrinsic = extrinsic.copied()
    let metadata = metadata.copied()
    let types = types.copied()
    return CFutureData {
        await this.unowned((any SubstrateService).self).castError().asyncFlatMap {
            await $0.signTransation(type: type, path: path, extrinsic: extrinsic,
                                    metadata: metadata, types: types)
        }
    }
}
