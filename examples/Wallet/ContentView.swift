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
        TextField("Signature", text: $data.signature)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(data: WalletData())
    }
}
