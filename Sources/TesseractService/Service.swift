//
//  Service.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

public protocol Service: AnyObject {
    associatedtype Core: CoreService
    
    func toCore() -> Core
}

public protocol CoreService: CSwiftAnyDropPtr {
    func register(in tesseract: UnsafeMutablePointer<ServiceTesseract>) -> ServiceTesseract
}
