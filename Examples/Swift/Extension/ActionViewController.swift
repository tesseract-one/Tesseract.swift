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
    
    var continuation: UnsafeContinuation<Bool, Error>?
    
    var tesseract: Tesseract!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = WalletData()
        let service = TestSigningService(delegate: self, signature: data.signature)
        
        tesseract = try! Tesseract()
            .transport(IPCTransportIOS(self))
            .service(service)
    }
    
    @MainActor
    func acceptTx(tx: String) async throws -> Bool {
        try await withUnsafeThrowingContinuation { cont in
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
        self.continuation?.resume(throwing: TesseractError.cancelled)
        self.continuation = nil
    }
}
