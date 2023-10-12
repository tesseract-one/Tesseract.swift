//
//  ActionViewController.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import MobileCoreServices
import CWallet
import TesseractTransportsService

class ActionViewController: UIViewController, NativeUIDelegate {
 
    @IBOutlet weak var textView: UILabel!
    
    var context: AppContextPtr!
    var continuation: UnsafeContinuation<Result<Bool, TesseractError>, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transport = IPCTransportIOS(self).toCore()
        let data = WalletData()
        
        self.context = try! TResult<AppContextPtr>.wrap { value, error in
            wallet_extension_init(data.signature,
                                  NativeUI(delegate: self).toCore(),
                                  transport, value, error)
        }.get()
    }
    
    @MainActor
    func approveTx(tx: String) async -> Result<Bool, TesseractError> {
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
        self.continuation?.resume(returning: .failure(.cancelled))
        self.continuation = nil
    }

    deinit {
        wallet_extension_deinit(&self.context)
    }
}

extension AppContextPtr: CType {}
