//
//  NativeUI.swift
//  TestExtension
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
import CWallet

protocol NativeUIDelegate: AnyObject {
    func approveTx(tx: String) async throws -> Bool
}

class NativeUI {
    weak var delegate: NativeUIDelegate!
    
    init(delegate: NativeUIDelegate) {
        self.delegate = delegate
    }
    
    func approveTx(tx: String) async throws -> Bool {
        try await self.delegate.approveTx(tx: tx)
    }
    
    func asNative() -> CWallet.UI {
        CWallet.UI(
            ptr: Unmanaged.passRetained(self).toOpaque(),
            approve_tx: native_ui_approve_tx,
            release: native_ui_release
        )
    }
}

extension UnsafePointer where Pointee == CWallet.UI {
    func unowned() -> NativeUI {
        Unmanaged<NativeUI>.fromOpaque(self.pointee.ptr).takeUnretainedValue()
    }
}

extension UnsafeMutablePointer where Pointee == CWallet.UI {
    func unowned() -> NativeUI {
        Unmanaged<NativeUI>.fromOpaque(self.pointee.ptr).takeUnretainedValue()
    }
    
    func owned() -> NativeUI {
        Unmanaged<NativeUI>.fromOpaque(self.pointee.ptr).takeRetainedValue()
    }
}


private func native_ui_approve_tx(this: UnsafePointer<UI>!, tx: CStringRef!) -> CFutureBool {
    CFutureBool {
        try await this.unowned().approveTx(tx: tx.copied())
    }
}

private func native_ui_release(this: UnsafeMutablePointer<CWallet.UI>!) {
    let _ = this.owned()
}
