//
//  DAppApp.swift
//  DApp
//
//  Created by Yehor Popovych on 16.11.2022.
//

import SwiftUI

@main
struct DAppApp: App {
    @StateObject var alerts: AlertProvider
    var core: AppCore
    
    public init() {
        let alerts = AlertProvider()
        self._alerts = StateObject(wrappedValue: alerts)
        self.core = AppCore(alerts: alerts)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(core: core, alerts: alerts)
        }
    }
}
