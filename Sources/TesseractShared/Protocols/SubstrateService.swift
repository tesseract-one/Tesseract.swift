//
//  SubstrateService.swift
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
    static let substrate = BlockchainProtocol(ptr: tesseract_protocol_substrate_new())
}

public enum SubstrateAccountType {
    case sr25519
    case ed25519
    case ecdsa
}

public struct SubstrateGetAccountResponse {
    public let pubKey: Data
    public let path: String
    
    public init(pubKey: Data, path: String) {
        self.pubKey = pubKey
        self.path = path
    }
}

public protocol SubstrateServiceResult: Service {
    func getAccountRes(
        type: SubstrateAccountType
    ) async -> Result<SubstrateGetAccountResponse, TesseractError>
    
    func signTransactionRes(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async -> Result<Data, TesseractError>
}

public protocol SubstrateService: SubstrateServiceResult {
    func getAccount(
        type: SubstrateAccountType
    ) async throws -> SubstrateGetAccountResponse
    
    func signTransaction(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async throws -> Data
}

public extension SubstrateServiceResult {
    var proto: BlockchainProtocol { .substrate }
}

public extension SubstrateService {
    func getAccountRes(
        type: SubstrateAccountType
    ) async -> Result<SubstrateGetAccountResponse, TesseractError> {
        await Result { try await getAccount(type: type) }
    }
    
    func signTransactionRes(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async -> Result<Data, TesseractError> {
        await Result {
            try await signTransaction(type: type, path: path,
                                      extrinsic: extrinsic,
                                      metadata: metadata,
                                      types: types)
        }
    }
}

extension CTesseract.SubstrateService: CAnyObjectPtr {}

extension CTesseract.SubstrateAccountType: CType {
    public init() { self.init(0) }
}

extension CTesseract.SubstrateGetAccountResponse: CType, CPtr {
    public typealias Val = SubstrateGetAccountResponse
    
    public func copied() -> SubstrateGetAccountResponse {
        SubstrateGetAccountResponse(pubKey: public_key.copied(),
                                    path: path.copied())
    }
    
    public mutating func owned() -> SubstrateGetAccountResponse {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_substrate_get_account_response_free(&self)
    }
}

extension SubstrateGetAccountResponse: AsCPtrCopy {
    public typealias CopyPtr = CTesseract.SubstrateGetAccountResponse
    
    public func copiedPtr() -> CTesseract.SubstrateGetAccountResponse {
        CTesseract.SubstrateGetAccountResponse(public_key: pubKey.copiedPtr(),
                                               path: path.copiedPtr())
    }
}

extension SubstrateAccountType: CValue {
    public typealias CVal = CTesseract.SubstrateAccountType
    
    public init(cvalue val: CTesseract.SubstrateAccountType) {
        switch val {
        case SubstrateAccountType_Ed25519: self = .ed25519
        case SubstrateAccountType_Sr25519: self = .sr25519
        case SubstrateAccountType_Ecdsa: self = .ecdsa
        default: fatalError("Unsupported account type: \(val)")
        }
    }
    
    public var asCValue: CTesseract.SubstrateAccountType {
        switch self {
        case .sr25519: return SubstrateAccountType_Sr25519
        case .ed25519: return SubstrateAccountType_Ed25519
        case .ecdsa: return SubstrateAccountType_Ecdsa
        }
    }
}

extension CFuture_SubstrateGetAccountResponse: CFuturePtr {
    public typealias CVal = CTesseract.SubstrateGetAccountResponse
    public typealias SVal = SubstrateGetAccountResponse
    
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
}
