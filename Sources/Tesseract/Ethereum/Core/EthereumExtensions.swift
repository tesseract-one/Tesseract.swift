//
//  EthereumExtensions.swift
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

import Ethereum
import OpenWallet

public extension Tesseract {
    var ethereum: InstanceAPIRegistry {
        return registry
    }
    
    static var Ethereum: ModuleAPIRegistry {
        return Tesseract.default.registry
    }
    
    private var registry: APIRegistry {
        if let registry = extensions[.ethereum] as? APIRegistry {
            return registry
        }
        let registry = APIRegistry(signProvider: openWallet)
        extensions[.ethereum] = registry
        return registry
    }
}

public extension TesseractExtension {
    static let ethereum: TesseractExtension = TesseractExtension(rawValue: "Tesseract.Ethereum")
}
