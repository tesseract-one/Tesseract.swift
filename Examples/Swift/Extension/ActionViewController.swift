//
//  ActionViewController.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import MobileCoreServices
import TesseractService

class ActionViewController: UIViewController, TestService {
    @IBOutlet weak var textView: UILabel!
    
    var continuation: UnsafeContinuation<CResult<String>, Never>?
    
    var tesseract: Tesseract!
    var data: WalletData!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        data = WalletData()
        tesseract = Tesseract()
            .transport(IPCTransportIOS(self))
            .service(self)
    }
    
    @MainActor
    func signTransation(req: String) async -> CResult<String> {
        return await withUnsafeContinuation { cont in
            self.continuation = cont
            self.textView.text = req
        }
    }
    
    func signed() -> String {
        self.textView.text! + data.signature
    }
    

    @IBAction func allow() {
        self.continuation?.resume(returning: .success(signed()))
        self.continuation = nil
    }
    
    @IBAction func reject() {
        self.continuation?.resume(returning: .failure(.canceled))
        self.continuation = nil
    }
    
    @IBAction func cancel() {
        self.continuation?.resume(returning: .failure(.canceled))
        self.continuation = nil
    }
}
