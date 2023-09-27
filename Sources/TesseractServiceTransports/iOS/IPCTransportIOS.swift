//
//  IPCTransportIOS.swift
//  TesseractService
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import TesseractShared

public class IPCTransportIOS {
    private var context: NSExtensionContext
    
    public init(context: NSExtensionContext) {
        self.context = context
    }
    
    func rawRequest() async -> Result<(data: Data, uti: String), CError> {
        let item = context.inputItems
            .compactMap{$0 as? NSExtensionItem}
            .compactMap{$0.attachments}
            .flatMap{$0}
            .first
        
        guard let item = item else {
            return .failure(.emptyRequest(message: "No attachment items"))
        }
                
        guard let requestUTI = item.registeredTypeIdentifiers.first else {
            return .failure(.emptyRequest(message: "No items UTI"))
        }
        
        let request: NSSecureCoding
        do {
            request = try await item.loadItem(forTypeIdentifier: requestUTI,
                                              options: nil)
        } catch {
            return .failure(.nested(error: error))
        }
        
        guard let data = request as? Data else {
            return .failure(.unsupportedDataType(
                message: "Wrong message type: \(request)"
            ))
        }
        
        return .success((data: data, uti: requestUTI))
    }
    
    func sendResponse(data: Data, uti: String) async -> Result<(), CError> {
        let reply = NSExtensionItem()
        reply.attachments = [
            NSItemProvider(item: data as NSData, typeIdentifier: uti)
        ]
        return await withUnsafeContinuation { cont in
            context.completeRequest(returningItems: [reply]) { expired in
                if expired {
                    cont.resume(returning: .failure(.requestExpired(message: "Expired")))
                } else {
                    cont.resume(returning: .success(()))
                }
            }
        }
    }
    
    func sendError(error: CError) {
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
            let result = await self.transport.rawRequest().asyncFlatMap { (data, uti) in
                await self.processor.process(data: data).asyncFlatMap {
                    await self.transport.sendResponse(data: $0, uti: uti)
                }
            }
            switch result {
            case .failure(let err): self.transport.sendError(error: err)
            default: break
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

