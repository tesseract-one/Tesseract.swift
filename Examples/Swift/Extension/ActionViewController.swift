//
//  ActionViewController.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import MobileCoreServices
import TesseractService

class ActionViewController: UIViewController, TestSigningServiceDelegate {
    @IBOutlet weak var textView: UILabel!
    
    var continuation: UnsafeContinuation<CResult<Bool>, Never>?
    
    var tesseract: Tesseract!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = WalletData()
        let service = TestSigningService(delegate: self, signature: data.signature)
        
        tesseract = Tesseract()
            .transport(IPCTransportIOS(self))
            .service(service)
    }
    
    @MainActor
    func acceptTx(tx: String) async -> CResult<Bool> {
        return await withUnsafeContinuation { cont in
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
}
