//
//  AlertProvider.swift
//  DApp
//
//  Created by Yehor Popovych on 22.11.2022.
//

import Foundation
import TesseractUtils
import CApp

final class AlertProvider: ObservableObject {
    public struct Alert: Identifiable {
        let message: String
        public var id: String { message }
    }
    
    @Published var alert: Alert? = nil
    
    @MainActor
    func showAlert(alert: String) {
        self.alert = Alert(message: alert)
    }
}
