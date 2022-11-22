//
//  ContentView.swift
//  TesseractTest
//
//  Created by Yehor Popovych on 15.07.2022.
//

import SwiftUI

struct ContentView: View {
    let core: AppCore?
    @ObservedObject var alerts: AlertProvider
    
    var body: some View {
        NavigationView {
            List {
                Text("Client Application")
                Button("Run Test", action: runTest)
            }
            .navigationTitle("Client App")
        }
        .alert(item: $alerts.alert) { alert in
            Alert(title: Text("Error"), message: Text(alert.message))
        }
    }
    
    func runTest() {
        Task {
            let signed = try? await self.core?.signTx(tx: "TEST")
            print("Signed!", signed)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(core: nil, alerts: AlertProvider())
    }
}
