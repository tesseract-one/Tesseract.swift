//
//  TesseractDelegate.swift
//  
//
//  Created by Yehor Popovych on 20/11/2023.
//

import Foundation
import CTesseract
import TesseractShared
#if !COCOAPODS
@_exported import TesseractTransportsClient
#endif

public protocol TesseractDelegate: AnyObject {
    func select(transports: Dictionary<String, Status>) async -> String?
}

public extension TesseractDelegate {
    func toCore() -> ClientTesseractDelegate {
        var delegate = ClientTesseractDelegate(value: self)
        delegate.select_transport = delegate_select_transport
        return delegate
    }
}

extension ClientTesseractDelegate: CSwiftAnyDropPtr {}

extension CKeyValue_CString__ClientStatus: CKeyValue, CPtr {
    public typealias CKey = CString
    public typealias CVal = ClientStatus
    public typealias SVal = KeyValue<String, Status>
    
    public func copied() -> KeyValue<String, Status> {
        KeyValue(key: key.copied(), value: val.copied())
    }
    
    public mutating func owned() -> KeyValue<String, Status> {
        KeyValue(key: key.owned(), value: val.owned())
    }
    
    public mutating func free() {
        key.free()
        val.free()
    }
}

extension ClientTransportsStatusRef: CPtrDictionaryPtrRef {
    public typealias SElement = KeyValue<String, Status>
    public typealias CElement = CKeyValue_CString__ClientStatus
}

private func delegate_select_transport(
    this: UnsafePointer<ClientTesseractDelegate>!,
    transports: ClientTransportsStatusRef
) -> CFutureString {
    let trans: Dictionary<String, Status> = transports.copiedDictionary()
    return CFutureString {
        await this.unowned(TesseractDelegate.self).castError().asyncFlatMap {
            guard let result = await $0.select(transports: trans) else {
                return .failure(TesseractError.cancelled)
            }
            return .success(result)
        }
    }
}
