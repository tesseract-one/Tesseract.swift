//
//  TestService.swift
//  
//
//  Created by Yehor Popovych on 07/11/2023.
//

import Foundation
#if !COCOAPODS
import TesseractTransportsShared
#endif

public protocol TestService {
    func signTransation(req: String) async -> Result<String, TesseractError>
}
