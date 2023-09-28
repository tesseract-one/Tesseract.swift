//
//  NativeUI.swift
//  TestExtension
//
//  Created by Yehor Popovych on 14.11.2022.
//

import Foundation
import TesseractServiceTransports
import CWallet

protocol NativeUIDelegate: AnyObject {
    func approveTx(tx: String) async -> CResult<Bool>
}

extension CWallet.UI: CSwiftDropPtr {
    public typealias SObject = NativeUI
}

extension CWallet.UI {
    public init(ui: NativeUI) {
        self = CWallet.UI(value: ui)
        self.approve_tx = native_ui_approve_tx
    }
}

public class NativeUI {
    weak var delegate: NativeUIDelegate!
    
    init(delegate: NativeUIDelegate) {
        self.delegate = delegate
    }
    
    func approveTx(tx: String) async -> CResult<Bool> {
        await self.delegate.approveTx(tx: tx)
    }
    
    func toCore() -> CWallet.UI {
        CWallet.UI(ui: self)
    }
}

private func native_ui_approve_tx(this: UnsafePointer<UI>!, tx: CStringRef!) -> CFutureBool {
    let tx = tx.copied()!
    return CFutureBool {
        await this.unowned().asyncFlatMap { await $0.approveTx(tx: tx) }
    }
}
