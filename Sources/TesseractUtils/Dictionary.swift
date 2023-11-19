//
//  Dictionary.swift
//
//
//  Created by Yehor Popovych on 17.07.2022.
//

import Foundation
import CTesseractShared

public protocol CKeyValue {
    associatedtype CKey
    associatedtype CVal
    
    associatedtype SVal: SKeyValue
    
    var key: CKey { get set }
    var val: CVal { get set }
    
    init(key: CKey, val: CVal)
}

public protocol SKeyValue {
    associatedtype Key: Hashable
    associatedtype Value
    init(key: Key, value: Value)
    var asTuple: (Key, Value) { get }
}

public struct KeyValue<Key: Hashable, Value>: SKeyValue {
    public let key: Key
    public let value: Value
    public init(key: Key, value: Value) {
        self.key = key; self.value = value
    }
    public var asTuple: (Key, Value) { (key, value) }
}

public protocol FromKeyValueArray {
    associatedtype TKey: Hashable
    associatedtype TValue
    
    init<KV: SKeyValue>(kv: Array<KV>) where KV.Key == TKey, KV.Value == TValue
}

public protocol CDictionaryPtr: CArrayPtr
    where CElement: CKeyValue, SElement == CElement.SVal
{
    func copiedDictionary<D: FromKeyValueArray>() -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value

    func copiedDictionary<D: FromKeyValueArray>(_ type: D.Type) -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value

    mutating func ownedDictionary<D: FromKeyValueArray>() -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value

    mutating func ownedDictionary<D: FromKeyValueArray>(_ type: D.Type) -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value
}

public extension CDictionaryPtr {
    func copiedDictionary<D: FromKeyValueArray>() -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value
    {
        self.copiedDictionary(D.self)
    }

    func copiedDictionary<D: FromKeyValueArray>(_ type: D.Type) -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value
    {
        type.init(kv: self.copied())
    }

    mutating func ownedDictionary<D: FromKeyValueArray>() -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value
    {
        self.ownedDictionary(D.self)
    }

    mutating func ownedDictionary<D: FromKeyValueArray>(_ type: D.Type) -> D
        where D.TKey == SElement.Key, D.TValue == SElement.Value
    {
        type.init(kv: self.owned())
    }
}

public protocol CCopyDictionaryPtr: CDictionaryPtr, CCopyArrayPtr {}

public protocol CCopyConvertDictionaryPtr: CDictionaryPtr, CCopyConvertArrayPtr {}

public protocol CPtrDictionaryPtr: CDictionaryPtr, CPtrArrayPtr {}

extension Dictionary: FromKeyValueArray {
    public typealias TKey = Key
    public typealias TValue = Value
    
    public init<KV: SKeyValue>(kv: Array<KV>) where KV.Key == TKey, KV.Value == TValue {
        self.init(uniqueKeysWithValues: kv.map { $0.asTuple })
    }
}

//protocol WithCKVArray: Sequence where Element == (key: Key, value: Value) {
//    associatedtype Key: Hashable
//    associatedtype Value
//    
//    func withCKVArr<A: CArray, T>(fn: @escaping (A) throws -> T) rethrows -> T
//    where
//        A.CElement: CKeyValue,
//        Key == A.CElement.Key,
//        Value == A.CElement.Value
//    
//    func withCKVArray<A: CArray, T>(
//        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue, Value == A.CElement.Value
//    
//    func withCKVArray<A: CArray, T>(
//        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue, Key == A.CElement.Key
//    
//    func withCKVArray<A: CArray, T>(
//        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
//        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue
//}
//
//extension WithCKVArray {
//    func withCKVArr<A: CArray, T>(fn: @escaping (A) throws -> T) rethrows -> T
//    where
//        A.CElement: CKeyValue,
//        Key == A.CElement.Key,
//        Value == A.CElement.Value
//    {
//        try Array(self).withContiguousStorageIfAvailable { storage in
//            let mapped = storage.map { A.CElement($0) }
//            return try mapped.withUnsafeBufferPointer {
//                try fn(A(ptr: $0.baseAddress, len: UInt($0.count)))
//            }
//        }!
//    }
//    
//    func withCKVArray<A: CArray, T>(
//        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue, Value == A.CElement.Value {
//        try Array(self).withCArray(
//            with: { el, fn in
//                try withKey(el.key) { try fn(A.CElement(($0, el.value))) }
//            },
//            fn: fn
//        )
//    }
//    
//    func withCKVArray<A: CArray, T>(
//        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue, Key == A.CElement.Key {
//        try Array(self).withCArray(
//            with: { el, fn in
//                try withValue(el.value) { try fn(A.CElement((el.key, $0))) }
//            },
//            fn: fn
//        )
//    }
//    
//    func withCKVArray<A: CArray, T>(
//        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
//        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
//        fn: @escaping (A) throws -> T
//    ) rethrows -> T where A.CElement: CKeyValue {
//        try Array(self).withCArray(
//            with: { el, fn in
//                try withKey(el.key) { key in
//                    try withValue(el.value) { value in
//                        try fn(A.CElement((key, value)))
//                    }
//                }
//            },
//            fn: fn
//        )
//    }
//}
//
//extension Dictionary: WithCKVArray {}
