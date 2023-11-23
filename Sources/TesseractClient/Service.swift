//
//  Service.swift
//  
//
//  Created by Yehor Popovych on 22/11/2023.
//

import Foundation
import CTesseract
import TesseractShared

public protocol Service: AnyObject {
    init(tesseract: UnsafePointer<ClientTesseract>)
}

public protocol CoreService: CAnyObjectPtr {
    static func get(from tesseract: UnsafePointer<ClientTesseract>) -> Self
}

open class ServiceBase<S: CoreService>: Service {
    public var service: S
    
    public required init(tesseract: UnsafePointer<ClientTesseract>) {
        service = S.get(from: tesseract)
    }
    
    deinit {
        service.free()
    }
}
