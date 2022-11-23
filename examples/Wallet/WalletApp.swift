//
//  WalletApp.swift
//  Wallet
//
//  Created by Yehor Popovych on 16.11.2022.
//

import SwiftUI

@main
struct WalletApp: App {
    @StateObject var data = WalletData()
    
    var body: some Scene {
        WindowGroup {
            ContentView(data: data)
        }
    }
}
