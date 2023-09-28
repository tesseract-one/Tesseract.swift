//
//  ActionViewController.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import MobileCoreServices
import CWallet
import TesseractServiceTransports

class ActionViewController: UIViewController, NativeUIDelegate {
 
    @IBOutlet weak var textView: UILabel!
    
    var context: AppContextPtr!
    var continuation: UnsafeContinuation<CResult<Bool>, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transport = IPCTransportIOS(self).toCore()
        let data = WalletData()
        
        self.context = wallet_extension_init(data.signature,
                                             NativeUI(delegate: self).toCore(),
                                             transport)
    }
    
    @MainActor
    func approveTx(tx: String) async -> CResult<Bool> {
        await withUnsafeContinuation { cont in
            self.continuation = cont
            self.textView.text = tx
        }
    }

    @IBAction func allow() {
        self.continuation?.resume(returning: .success(true))
        self.continuation = nil
    }
    
    @IBAction func reject() {
        self.continuation?.resume(returning: .success(false))
        self.continuation = nil
    }
    
    @IBAction func cancel() {
        self.continuation?.resume(returning: .failure(.canceled))
        self.continuation = nil
    }

    deinit {
        wallet_extension_deinit(&self.context)
    }
}
