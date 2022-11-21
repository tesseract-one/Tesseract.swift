//
//  WalletData.swift
//  Examples
//
//  Created by Ostap Danylovych on 21.11.2022.
//

import Foundation

class WalletData: ObservableObject {
    private var defaults = UserDefaults(suiteName: "group.one.tesseract.Wallet")!
    
    @Published var signature: String {
        didSet {
            defaults.set(signature, forKey: "signature")
        }
    }
    
    init() {
        signature = defaults.string(forKey: "signature") ?? ""
    }
}
