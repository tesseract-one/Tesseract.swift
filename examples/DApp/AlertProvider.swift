//
//  AlertProvider.swift
//  DApp
//
//  Created by Yehor Popovych on 22.11.2022.
//

import Foundation
import TesseractUtils
import CApp

public class AlertProvider: ObservableObject, AsVoidSwiftPtr {
    public struct Alert: Identifiable {
        let message: String
        public var id: String { message }
    }
    
    @Published var alert: Alert? = nil
    
    @MainActor
    func showAlert(alert: String) {
        self.alert = Alert(message: alert)
    }
    
    func asNative() -> CApp.AlertProvider {
        var provider = CApp.AlertProvider(owned: self)
        provider.show_alert = alert_provider_show_alert
        provider.release = alert_provider_release
        return provider
    }
}

private func alert_provider_show_alert(this: UnsafePointer<CApp.AlertProvider>!, message: CStringRef!) {
    let message = message!.copied()
    Task {
        await this.unowned().showAlert(alert: message)
    }
}

private func alert_provider_release(this: UnsafeMutablePointer<CApp.AlertProvider>!) {
    let _ = this.owned()
}

extension CApp.AlertProvider: CSwiftPtr {
    public typealias SObject = AlertProvider
}
