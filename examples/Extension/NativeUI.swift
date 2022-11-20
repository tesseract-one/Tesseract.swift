//
//  NativeUI.swift
//  TestExtension
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
import TesseractUtils
import CWallet

protocol NativeUIDelegate: AnyObject {
    func approveTx(tx: String) async throws -> Bool
}

extension CWallet.UI: CSwiftPtr {
    public typealias SObject = NativeUI
}

extension CWallet.UI {
    public init(ui: NativeUI) {
        self = CWallet.UI(owned: ui)
        self.approve_tx = native_ui_approve_tx
        self.release = native_ui_release
    }
}

public class NativeUI: AsVoidSwiftPtr {
    weak var delegate: NativeUIDelegate!
    
    init(delegate: NativeUIDelegate) {
        self.delegate = delegate
    }
    
    func approveTx(tx: String) async throws -> Bool {
        try await self.delegate.approveTx(tx: tx)
    }
    
    func asNative() -> CWallet.UI {
        CWallet.UI(ui: self)
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
