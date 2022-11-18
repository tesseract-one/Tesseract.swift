//
//  IPCTransportIOS.swift
//  TesseractService
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import TesseractUtils
import TesseractCommon

public class IPCTransportIOS {
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
            throw CError.emptyRequest(message: "No attachment items")
        }
                
        guard let requestUTI = item.registeredTypeIdentifiers.first else {
            throw CError.emptyRequest(message: "No items UTI")
        }
        
        let request = try await item.loadItem(forTypeIdentifier: requestUTI, options: nil)
        
        guard let data = request as? Data else {
            throw CError.unsupportedDataType(message: "Wrong message type: \(request)")
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
                    cont.resume(throwing: CError.requestExpired(message: "Expired"))
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

public class BoundIPCTransportIOS: BoundTransport {
    public let transport: IPCTransportIOS
    public let processor: TransportProcessor
    
    public init(transport: IPCTransportIOS, processor: TransportProcessor) {
        self.transport = transport
        self.processor = processor
        self.process()
    }
    
    private func process() {
        Task {
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

extension IPCTransportIOS: Transport {
    public func bind(processor: TransportProcessor) -> BoundTransport {
        BoundIPCTransportIOS(transport: self, processor: processor)
    }
}

extension IPCTransportIOS {
    public convenience init(_ vc: UIViewController) {
        self.init(context: vc.extensionContext!)
    }
}

