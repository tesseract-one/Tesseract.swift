//
//  Service.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
#if !COCOAPODS
import TesseractTransportsShared
#endif

public protocol Service: AnyObject {
    var proto: BlockchainProtocol { get }
}
