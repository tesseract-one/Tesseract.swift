//
//  AppCore.swift
//  TestApp
//
//  Created by Yehor Popovych on 15.11.2022.
//

import Foundation
import TesseractClient

final class TesseractTransportDelegate: TesseractDelegate {
    private let alerts: AlertProvider
    
    init(alerts: AlertProvider) {
        self.alerts = alerts
    }
    
    func select(transports: Dictionary<String, Status>) async -> String? {
        assert(transports.count == 1, "How the heck do we have more than one transport here?")
        let transport = transports.first!
        switch transport.value {
        case .ready: return transport.key
        case .unavailable(let why):
            await alerts.showAlert(alert: "Transport '\(transport.key)' is not available because of the following reason: \(why)")
            return nil
        case .error(let err):
            await alerts.showAlert(alert: "Transport '\(transport.key)' is not available because the transport produced an error: \(err)")
            return nil
        }
    }
}

struct AppCore {
    private let service: TestService
    
    init(alerts: AlertProvider) {
        service = try! Tesseract
            .default(delegate: TesseractTransportDelegate(alerts: alerts))
            .service(TestService.self)
    }
    
    func signTx(tx: String) async throws -> String {
        try await service.signTransaction(req: tx)
    }
}
