//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 27/09/2023.
//

import Foundation
import CTesseract
import TesseractShared

extension CTesseract.TestService: CoreService {
    public func register(
        in tesseract: UnsafeMutablePointer<ServiceTesseract>
    ) -> ServiceTesseract {
        tesseract_service_add_test_service(tesseract, self)
    }
}

public protocol TestServiceResult: TesseractShared.TestServiceResult, Service
    where Core == CTesseract.TestService {}

public protocol TestService: TestServiceResult, TesseractShared.TestService {}

public extension TestServiceResult {
    func toCore() -> Core {
        var value = Core(value: self)
        value.sign_transaction = test_service_sign
        return value
    }
}

private func test_service_sign(this: UnsafePointer<CTesseract.TestService>!,
                               req: CStringRef!) -> CFutureString
{
    let req = req.copied()
    return CFutureString {
        await this.unowned((any TestServiceResult).self).castError().asyncFlatMap {
            await $0.signTransactionRes(req: req)
        }
    }
}
