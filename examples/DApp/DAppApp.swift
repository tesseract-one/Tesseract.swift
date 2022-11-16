//
//  DAppApp.swift
//  DApp
//
//  Created by Yehor Popovych on 16.11.2022.
//

import SwiftUI

@main
struct DAppApp: App {
    var core = AppCore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core)
        }
    }
}
