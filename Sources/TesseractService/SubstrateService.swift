//
//  SubstrateService.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

extension SubstrateGetAccountResponse: CValue, CType {
    public typealias CVal = Self
}

extension CFutureValue_SubstrateGetAccountResponse: CFutureValueValue {
    public typealias Val = SubstrateGetAccountResponse
    public typealias Tag = CFutureValue_SubstrateGetAccountResponse_Tag
    
    public static var valueTag: CFutureValue_SubstrateGetAccountResponse_Tag {
        CFutureValue_SubstrateGetAccountResponse_Value_SubstrateGetAccountResponse
    }
    
    public static var errorTag: CFutureValue_SubstrateGetAccountResponse_Tag {
        CFutureValue_SubstrateGetAccountResponse_Error_SubstrateGetAccountResponse
    }
    
    public static var noneTag: CFutureValue_SubstrateGetAccountResponse_Tag {
        CFutureValue_SubstrateGetAccountResponse_None_SubstrateGetAccountResponse
    }
}

extension CFuture_SubstrateGetAccountResponse: CFuturePtr {
    public typealias CVal = CFutureValue_SubstrateGetAccountResponse
    public typealias Val = (pubKey: Data, path: String)
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
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

extension CTesseract.SubstrateService: NativeService {
    public func register(
        in tesseract: UnsafeMutablePointer<ServiceTesseract>
    ) -> ServiceTesseract {
        tesseract_service_add_substrate_service(tesseract, self)
    }
}

public protocol SubstrateService: Service where Native == CTesseract.SubstrateService {
    func getAccount(
        type: SubstrateAccountType
    ) async throws -> (pubKey: Data, path: String)
    
    func signTransation(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async throws -> Data
}

public extension SubstrateService {
    func asNative() -> Native {
        var value = Native(value: self)
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
        try await (this.unowned() as! (any SubstrateService)).getAccount(type: accountType)
    }
}

private func substrate_service_sign(
    this: UnsafePointer<CTesseract.SubstrateService>!,
    type: SubstrateAccountType, path: CStringRef!,
    extrinsic: UnsafePointer<UInt8>!, extrinsicLen: UInt,
    metadata: UnsafePointer<UInt8>!, metadataLen: UInt,
    types: UnsafePointer<UInt8>!, typesLen: UInt
) -> CFutureData {
    let path = path.copied()!
    let extrinsic = Data(bytes: extrinsic, count: Int(extrinsicLen))
    let metadata = Data(bytes: metadata, count: Int(metadataLen))
    let types = Data(bytes: types, count: Int(typesLen))
    return CFutureData {
        try await (this.unowned() as! (any SubstrateService)).signTransation(
            type: type, path: path, extrinsic: extrinsic,
            metadata: metadata, types: types
        )
    }
}
