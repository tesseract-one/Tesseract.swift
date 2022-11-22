//
//  ActionViewController.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import MobileCoreServices
import CWallet
import TesseractService

class ActionViewController: UIViewController, NativeUIDelegate {
 
    @IBOutlet weak var textView: UILabel!
    
    var context: AppContextPtr!
    var continuation: UnsafeContinuation<Bool, Error>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transport = IPCTransportIOS(self)
        let native = transport.asNative()
        
        let data = WalletData()
        let signature = data.signature
        self.context = signature.withRef { signature in
            wallet_extension_init(signature, NativeUI(delegate: self).asNative(), native)
        }
    }
    
    @MainActor
    func approveTx(tx: String) async throws -> Bool {
        return try await withUnsafeThrowingContinuation { cont in
            self.continuation = cont
            self.textView.text = tx
        }
    }

    @IBAction func allow() {
        self.continuation?.resume(returning: true)
        self.continuation = nil
    }
    
    @IBAction func reject() {
        self.continuation?.resume(returning: false)
        self.continuation = nil
    }
    
    @IBAction func cancel() {
        self.continuation?.resume(throwing: CError.canceled)
        self.continuation = nil
    }

    deinit {
        wallet_extension_deinit(self.context)
        self.context = nil
    }
}
