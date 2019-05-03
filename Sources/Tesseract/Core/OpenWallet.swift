//
//  OpenWallet.swift
//  Tesseract
//
//  Created by Yehor Popovych on 5/3/19.
//  Copyright © 2019 Tesseract Systems, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import OpenWallet

typealias OpenWalletClass = OpenWallet

public extension Tesseract {
    var OpenWallet: OpenWallet {
        get {
            if let openWallet = extensions[.openWallet] as? OpenWalletClass {
                return openWallet
            }
            let openWallet = OpenWalletClass()
            extensions[.openWallet] = openWallet
            return openWallet
        }
        set(openWallet) {
            extensions[.openWallet] = openWallet
        }
    }
    
    static var OpenWallet: OpenWallet {
        get {
            return Tesseract.default.OpenWallet
        }
        set(openWallet) {
            return Tesseract.default.OpenWallet = openWallet
        }
    }
}

public extension TesseractExtension {
    static let openWallet = TesseractExtension(rawValue: "Tesseract.OpenWallet")
}

