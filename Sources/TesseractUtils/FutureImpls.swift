//
//  FutureImpls.swift
//
//
//  Created by Yehor Popovych on 21.07.2022.
//

import Foundation
import CTesseract

extension CFutureValue_Nothing: CFutureValueValue {
    public typealias Val = Nothing
    
    public static var valueTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_Value_Nothing
    }
    
    public static var errorTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_Error_Nothing
    }
    
    public static var noneTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_None_Nothing
    }
}

extension CFutureNothing: CFuturePtr {    
    public typealias CVal = CFutureValue_Nothing
    public typealias Val = Void
    
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
    
    public static func convert(cvalue: inout Nothing) -> CResult<Void> {
        .success(())
    }
    
    public static func convert(value: inout Void) -> CResult<Nothing> {
        .success(.nothing)
    }
}

extension CFutureValue_CAnyRustPtr: CFutureValueValue {
    public typealias Val = CAnyRustPtr
    
    public static var valueTag: CFutureValue_CAnyRustPtr_Tag {
        CFutureValue_CAnyRustPtr_Value_CAnyRustPtr
    }

    public static var errorTag: CFutureValue_CAnyRustPtr_Tag {
        CFutureValue_CAnyRustPtr_Error_CAnyRustPtr
    }

    public static var noneTag: CFutureValue_CAnyRustPtr_Tag {
        CFutureValue_CAnyRustPtr_None_CAnyRustPtr
    }
}

extension CFutureAnyRustPtr: CFuturePtr {
    public typealias CVal = CFutureValue_CAnyRustPtr
    public typealias Val = CAnyRustPtr
    
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
    
    public static func convert(cvalue: inout CAnyRustPtr) -> CResult<CAnyRustPtr> {
        .success(cvalue)
    }
    
    public static func convert(value: inout CAnyRustPtr) -> CResult<CAnyRustPtr> {
        .success(value)
    }
}

extension CFutureValue_CData: CFutureValueValue {
    public typealias Val = CData
    
    public static var valueTag: CFutureValue_CData_Tag {
        CFutureValue_CData_Value_CData
    }
    
    public static var errorTag: CFutureValue_CData_Tag {
        CFutureValue_CData_Error_CData
    }
    
    public static var noneTag: CFutureValue_CData_Tag {
        CFutureValue_CData_None_CData
    }
}

extension CFutureData: CFuturePtr {
    public typealias CVal = CFutureValue_CData
    public typealias Val = Data
    
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
}

extension CFutureValue_CString: CFutureValuePtr {
    public typealias PtrVal = CString
    
    public static var valueTag: CFutureValue_CString_Tag {
        CFutureValue_CString_Value_CString
    }
    
    public static var errorTag: CFutureValue_CString_Tag {
        CFutureValue_CString_Error_CString
    }
    
    public static var noneTag: CFutureValue_CString_Tag {
        CFutureValue_CString_None_CString
    }
}

extension CFutureString: CFuturePtr {
    public typealias CVal = CFutureValue_CString
    public typealias Val = String
    
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
}

extension CFutureValue_bool: CFutureValueValue {
    public typealias Val = Bool
    
    public static var valueTag: CFutureValue_bool_Tag {
        CFutureValue_bool_Value_bool
    }
    
    public static var errorTag: CFutureValue_bool_Tag {
        CFutureValue_bool_Error_bool
    }
    
    public static var noneTag: CFutureValue_bool_Tag {
        CFutureValue_bool_None_bool
    }
}

extension CFutureBool: CFuturePtr {
    public typealias CVal = CFutureValue_bool
    public typealias Val = Bool
    
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
}
