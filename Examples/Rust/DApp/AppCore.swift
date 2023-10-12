//
//  AppCore.swift
//  TestApp
//
//  Created by Yehor Popovych on 15.11.2022.
//

import Foundation
import TesseractTransportsClient
import CApp

class AppCore {
    private var rust: AppContextPtr
    
    init(alerts: AlertProvider) {
        try! self.rust = TResult<AppContextPtr>.wrap { value, error in
            app_init(alerts.toCore(), IPCTransportIOS().toCore(), value, error)
        }.get()
    }
    
    func signTx(tx: String) async throws -> String {
        try await app_sign_data(self.rust, tx)
            .result.castError(TesseractError.self).get()
    }
    
    deinit {
        app_deinit(&self.rust)
    }
}

extension AppContextPtr: CType {}
