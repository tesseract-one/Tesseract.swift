//
//  AppCore.swift
//  TestApp
//
//  Created by Yehor Popovych on 15.11.2022.
//

import Foundation
import TesseractClient
import CApp

class AppCore {
    private var rust: AppContextPtr!
    
    init(alerts: AlertProvider) {
        self.rust = app_init(alerts.asNative(), IPCTransportIOS().asNative())
    }
    
    func signTx(tx: String) async throws -> String {
        try await tx.withRef { app_sign_data(self.rust, $0) }.value
    }
    
    deinit {
        app_deinit(self.rust)
        self.rust = nil
    }
}
