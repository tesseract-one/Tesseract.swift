//
//  BlockchainProtocol.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
import CTesseractShared
#if !COCOAPODS
import TesseractUtils
#endif

extension TesseractProtocol: CType, CFree {
    public func owned() -> BlockchainProtocol {
        BlockchainProtocol(ptr: self)
    }
    
    public mutating func free() {
        tesseract_protocol_free(&self)
    }
}

public final class BlockchainProtocol: AutoFree<TesseractProtocol> {
    public var id: String {
        ptr {
            var id = tesseract_protocol_get_id($0)
            return id.owned()
        }
    }
}

extension BlockchainProtocol: Equatable {
    public static func == (lhs: BlockchainProtocol, rhs: BlockchainProtocol) -> Bool {
        lhs.ptr { lhs in rhs.ptr { tesseract_protocol_is_equal(lhs, $0) } }
    }
}
