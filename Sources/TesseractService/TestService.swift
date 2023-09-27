//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

extension CTesseract.TestService: NativeService {    
    public func register(
        in tesseract: UnsafeMutablePointer<ServiceTesseract>
    ) -> ServiceTesseract {
        tesseract_service_add_test_service(tesseract, self)
    }
}

public protocol TestService: Service where Native == CTesseract.TestService {
    func signTransation(req: String) async -> CResult<String>
}

public extension TestService {
    func asNative() -> Native {
        var value = Native(value: self)
        value.sign_transaction = test_service_sign
        return value
    }
}

private func test_service_sign(this: UnsafePointer<CTesseract.TestService>!,
                               req: CStringRef!) -> CFutureString
{
    let req = req.copied()!
    return CFutureString {
        await this.unowned((any TestService).self).asyncFlatMap {
            await $0.signTransation(req: req)
        }
    }
}
