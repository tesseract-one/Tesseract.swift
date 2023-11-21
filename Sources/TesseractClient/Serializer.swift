//
//  Serializer.swift
//  
//
//  Created by Yehor Popovych on 20/11/2023.
//

import Foundation
import CTesseract

public enum Serializer: Equatable, Hashable {
    case json
    case cbor
}

public extension Serializer {
    static let `default`: Self = {
        #if DEBUG
        .json
        #else
        .cbor
        #endif
    }()
    
    func toCore() -> CTesseract.Serializer {
        switch self {
        case .json: return Serializer_Json
        case .cbor: return Serializer_Cbor
        }
    }
}
