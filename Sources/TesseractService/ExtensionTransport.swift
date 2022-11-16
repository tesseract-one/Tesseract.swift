//
//  Extension.swift
//  TestExtension
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import TesseractUtils

public class ExtensionTransport {
    private var context: NSExtensionContext
    
    public init(context: NSExtensionContext) {
        self.context = context
    }
    
    func rawRequest() async throws -> (data: Data, uti: String) {
        let item = context.inputItems
            .compactMap{$0 as? NSExtensionItem}
            .compactMap{$0.attachments}
            .flatMap{$0}
            .first
                
        guard let item = item else {
            throw CError.error(code: 0, message: "Empty Request")
        }
                
        guard let requestUTI = item.registeredTypeIdentifiers.first else {
            throw CError.error(code: 0, message: "Empty Request")
        }
        
        let request = try await item.loadItem(forTypeIdentifier: requestUTI, options: nil)
        
        guard let data = request as? Data else {
            throw CError.error(code: 1, message: "Wrong Message Body Type")
        }
        
        return (data: data, uti: requestUTI)
    }
    
    func sendResponse(data: Data, uti: String) async throws {
        let reply = NSExtensionItem()
        reply.attachments = [
            NSItemProvider(item: data as NSSecureCoding, typeIdentifier: uti)
        ]
        return try await withUnsafeThrowingContinuation { cont in
            context.completeRequest(returningItems: [reply]) { expired in
                if expired {
                    cont.resume(throwing: CError.error(code: 2, message: "Expired"))
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }
    
    func sendError(error: Error) {
        context.cancelRequest(withError: error)
    }
}

public class BoundExtensionTransport: BoundTransport {
    public let transport: ExtensionTransport
    public let processor: TransportProcessor
    
    public init(transport: ExtensionTransport, processor: TransportProcessor) {
        self.transport = transport
        self.processor = processor
        self.process()
    }
    
    private func process() {
        Task.detached {
            do {
                let (data, uti) = try await self.transport.rawRequest()
                let result = try await self.processor.process(data: data)
                try await self.transport.sendResponse(data: result, uti: uti)
            } catch {
                self.transport.sendError(error: error)
            }
        }
    }
}

extension ExtensionTransport: Transport {
    public func bind(processor: TransportProcessor) -> BoundTransport {
        BoundExtensionTransport(transport: self, processor: processor)
    }
}

extension ExtensionTransport {
    public convenience init(_ vc: UIViewController) {
        self.init(context: vc.extensionContext!)
    }
}

