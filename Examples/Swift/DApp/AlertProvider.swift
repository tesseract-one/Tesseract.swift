//
//  AlertProvider.swift
//  DApp
//
//  Created by Yehor Popovych on 22.11.2022.
//

import Foundation
import TesseractUtils
import CApp

public class AlertProvider: ObservableObject {
    public struct Alert: Identifiable {
        let message: String
        public var id: String { message }
    }
    
    @Published var alert: Alert? = nil
    
    @MainActor
    func showAlert(alert: String) {
        self.alert = Alert(message: alert)
    }
    
    func toCore() -> CApp.AlertProvider {
        var provider = CApp.AlertProvider(value: self)
        provider.show_alert = alert_provider_show_alert
        return provider
    }
}

private func alert_provider_show_alert(this: UnsafePointer<CApp.AlertProvider>!, message: CStringRef!) {
    let message = message!.copied()
    Task {
        try! await this.unowned().get().showAlert(alert: message)
    }
}

extension CApp.AlertProvider: CSwiftDropPtr {
    public typealias SObject = AlertProvider
}
