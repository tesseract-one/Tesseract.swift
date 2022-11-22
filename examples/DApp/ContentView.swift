//
//  ContentView.swift
//  TesseractTest
//
//  Created by Yehor Popovych on 15.07.2022.
//

import SwiftUI

struct ContentView: View {
    @State var transaction = "transaction"
    @State var signed: String?
    let core: AppCore?
    @ObservedObject var alerts: AlertProvider
    
    var body: some View {
        ZStack {
            Color(red: 0x4A/0xFF,
                  green: 0x93/0xFF,
                  blue: 0xE2/0xFF)
                .edgesIgnoringSafeArea(.top)
            Color.white
            VStack {
                HStack {
                    Text("Tesseract\nDemo dApp")
                        .font(.system(size: 48))
                    Spacer()
                }
                .padding()
                TextField("Transaction", text: $transaction)
                    .padding()
                Button("Sign", action: runTest)
                    .buttonStyle(.borderedProminent)
                    .padding()
                Text(signed ?? "Not Signed Yet")
                    .padding()
                Spacer()
            }
            .alert(item: $alerts.alert) { alert in
                Alert(title: Text("Error"), message: Text(alert.message))
            }
        }
    }
    
    func runTest() {
        Task {
            signed = try? await self.core?.signTx(tx: transaction)
            print("Signed!", signed as Any)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(core: nil, alerts: AlertProvider())
    }
}
