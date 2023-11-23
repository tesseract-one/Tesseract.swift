//
//  IPCTransportIOS.swift
//  TesseractService
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

public class IPCTransportIOS {
    private var context: NSExtensionContext
    
    public init(context: NSExtensionContext) {
        self.context = context
    }
    
    public convenience init(_ vc: UIViewController) {
        self.init(context: vc.extensionContext!)
    }
    
    func rawRequest() async -> Result<(data: Data, uti: String), Error> {
        let item = context.inputItems
            .compactMap{$0 as? NSExtensionItem}
            .compactMap{$0.attachments}
            .flatMap{$0}
            .first
        
        guard let item = item else {
            return .failure(.emptyRequest)
        }
                
        guard let requestUTI = item.registeredTypeIdentifiers.first else {
            return .failure(.emptyItemsUTI)
        }
        
        let request: NSSecureCoding
        do {
            request = try await item.loadItem(forTypeIdentifier: requestUTI,
                                              options: nil)
        } catch {
            return .failure(.nested(error as NSError))
        }
        
        guard let data = request as? Data else {
            return .failure(.unsupportedDataType("\(type(of: request))"))
        }
        
        return .success((data: data, uti: requestUTI))
    }
    
    func sendResponse(data: Data, uti: String) async -> Result<(), Error> {
        let reply = NSExtensionItem()
        reply.attachments = [
            NSItemProvider(item: data as NSData, typeIdentifier: uti)
        ]
        return await withUnsafeContinuation { cont in
            context.completeRequest(returningItems: [reply]) { expired in
                if expired {
                    cont.resume(returning: .failure(.requestExpired))
                } else {
                    cont.resume(returning: .success(()))
                }
            }
        }
    }
    
    func sendError(error: NSError) {
        context.cancelRequest(withError: error)
    }
}

public extension IPCTransportIOS {
    enum Error: Swift.Error, TesseractErrorConvertible, CustomNSError {
        case emptyRequest
        case emptyItemsUTI
        case emptyResponse
        case requestExpired
        case unsupportedDataType(String)
        case nested(NSError)
        
        public var tesseract: TesseractError {
            switch self {
            case .nested(let err): return .swift(error: err)
            default: return .swift(error: self as NSError)
            }
        }
        
        /// The domain of the error.
        public static var errorDomain: String { "IPCTransportIOS.Error" }

        /// The error code within the given domain.
        public var errorCode: Int {
            switch self {
            case .emptyRequest: return 0
            case .emptyItemsUTI: return 1
            case .emptyResponse: return 2
            case .requestExpired: return 3
            case .unsupportedDataType: return 4
            case .nested: return 5
            }
        }

        /// The user-info dictionary.
        public var errorUserInfo: [String : Any] {
            switch self {
            case .emptyRequest:
                return [NSLocalizedDescriptionKey: "Request is empty"]
            case .emptyItemsUTI:
                return [NSLocalizedDescriptionKey: "Empty UTI array"]
            case .emptyResponse:
                return [NSLocalizedDescriptionKey: "Response is empty"]
            case .requestExpired:
                return [NSLocalizedDescriptionKey: "Request is expired"]
            case .unsupportedDataType(let type):
                return [NSLocalizedDescriptionKey:
                            "Unsupported type \(type). Expected Data"]
            case .nested(let err):
                return [NSLocalizedDescriptionKey: "\(err)",
                             NSUnderlyingErrorKey: err]
            }
        }
    }
}

extension IPCTransportIOS {
    class Bound: BoundTransport {
        public let transport: IPCTransportIOS
        public let processor: TransportProcessor
        
        public init(transport: IPCTransportIOS, processor: TransportProcessor) {
            self.transport = transport
            self.processor = processor
            self.process()
        }
        
        private func process() {
            Task {
                let result = await self.transport.rawRequest()
                    .castError()
                    .asyncFlatMap { (data, uti) in
                        await self.processor.process(data: data).map { ($0, uti) }
                    }
                    .asyncFlatMap { (data, uti) in
                        await self.transport.sendResponse(data: data, uti: uti).castError()
                    }
                switch result {
                case .failure(let err): self.transport.sendError(error: err as NSError)
                default: break
                }
            }
        }
    }
}

extension IPCTransportIOS: Transport {
    public func bind(processor: TransportProcessor) -> any BoundTransport {
        Bound(transport: self, processor: processor)
    }
}
