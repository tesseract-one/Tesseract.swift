//
//  ContentView.swift
//  Wallet
//
//  Created by Yehor Popovych on 16.11.2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var data: WalletData
    
    var body: some View {
        ZStack {
            Color(red: 0xFF/0xFF,
                  green: 0x7D/0xFF,
                  blue: 0x00/0xFF)
                .edgesIgnoringSafeArea(.top)
            Color.white
            VStack {
                HStack {
                    Text("Tesseract\nDemo Wallet")
                        .font(.system(size: 48))
                    Spacer()
                }
                .padding()
                HStack {
                    Text("Choose your signature:")
                    Spacer()
                }
                .padding()
                TextField("Signature", text: $data.signature)
                    .padding()
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(data: WalletData())
    }
}
