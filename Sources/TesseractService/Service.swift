//
//  Service.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

public protocol Service: AnyObject, CoreConvertible where Core: CoreService {}

public protocol CoreService: CAnyObjectPtr {
    func register(in tesseract: UnsafeMutablePointer<ServiceTesseract>) -> ServiceTesseract
}
