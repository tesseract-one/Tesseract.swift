//
//  Service.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseractBin
import TesseractShared

public protocol Service: AnyObject {
    associatedtype Native: NativeService
    
    func asNative() -> Native
}

public protocol NativeService: CSwiftAnyDropPtr {
    func register(in tesseract: UnsafeMutablePointer<ServiceTesseract>) -> ServiceTesseract
}
