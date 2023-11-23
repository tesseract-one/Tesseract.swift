//
//  FutureImpls.swift
//
//
//  Created by Yehor Popovych on 21.07.2022.
//

import Foundation
import CTesseractShared

extension CFutureNothing: CFuturePtr {    
    public typealias CVal = Nothing
    public typealias SVal = Void
    
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
    
    public static func convert(cvalue: inout Nothing) -> CResult<Void> {
        .success(())
    }
    
    public static func convert(value: inout Void) -> CResult<Nothing> {
        .success(.nothing)
    }
}

extension CFutureAnyRustPtr: CFuturePtr {
    public typealias CVal = CAnyRustPtr
    public typealias SVal = CAnyRustPtr

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

    public static func convert(cvalue: inout CAnyRustPtr) -> CResult<CAnyRustPtr> {
        .success(cvalue)
    }

    public static func convert(value: inout CAnyRustPtr) -> CResult<CAnyRustPtr> {
        .success(value)
    }
}

extension CFutureData: CFuturePtr {
    public typealias CVal = CData
    public typealias SVal = Data
    
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

extension CFutureString: CFuturePtr {
    public typealias CVal = CString
    public typealias SVal = String
    
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

extension CFutureBool: CFuturePtr {
    public typealias CVal = Bool
    public typealias SVal = Bool
    
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
