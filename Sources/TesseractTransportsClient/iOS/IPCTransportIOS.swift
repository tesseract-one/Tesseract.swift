//
//  IPCTransportIOS.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
#if COCOAPODS
import TesseractShared
#else
import TesseractTransportsShared
#endif

public protocol ViewControllerPresenter {
    func present(vc: UIViewController) async -> Result<(), IPCTransportIOS.Error>
}

public struct RootViewControllerPresenter: ViewControllerPresenter {
    private var rootViewController: UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        return scene?
            .windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
    
    public init() {}
    
    @MainActor
    public func present(vc: UIViewController) async -> Result<(), IPCTransportIOS.Error> {
        return await withUnsafeContinuation { cont in
            guard let rootView = self.rootViewController else {
                cont.resume(
                    returning: .failure(.wrongInternalState("empty root view"))
                )
                return
            }
            let controller = rootView.presentedViewController ?? rootView
            controller.present(vc, animated: true) {
                cont.resume(returning: .success(()))
            }
        }
    }
}

public class IPCTransportIOS: Transport {
    public let presenter: ViewControllerPresenter
    public let id: String = "ipc"
    
    public init(presenter: ViewControllerPresenter = RootViewControllerPresenter()) {
        self.presenter = presenter
    }
    
    public func status(proto: String) async -> Status {
        guard let url = Self.url(proto: proto) else {
            return .error(
                Error.wrongProtocolId(proto).tesseract
            )
        }
        if await UIApplication.shared.canOpenURL(url) {
            return .ready
        } else {
            return .unavailable("Wallet is not installed")
        }
    }
    
    public func connect(proto: String) -> Connection {
        TransportConnection(proto: proto, presenter: presenter)
    }
    
    public static func url(proto: String) -> URL? {
        URL(string: "tesseract+\(proto)://")
    }
}

extension IPCTransportIOS {
    class TransportConnection: Connection {
        private var requests: Array<(UIActivityViewController,
                                     UnsafeContinuation<Result<(), Error>, Never>)>
        private var continuations: Array<UnsafeContinuation<Result<Data, Error>, Never>>
        
        public let proto: String
        public let presenter: ViewControllerPresenter
        
        public init(proto: String, presenter: ViewControllerPresenter) {
            self.requests = []
            self.continuations = []
            self.proto = proto
            self.presenter = presenter
        }
        
        public var uti: String { "one.tesseract.\(proto)" }
        
        @MainActor
        public func send(request: Data) async -> Result<(), TesseractError> {
            let vc = UIActivityViewController(
                activityItems: [NSItemProvider(item: request as NSData,
                                               typeIdentifier: uti)],
                applicationActivities: nil
            )
            
            vc.excludedActivityTypes = UIActivity.ActivityType.all
            
            vc.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                Task {
                    if let error = error {
                        await self.response(cancelled: !completed,
                                            result: .failure(.nested(error as NSError)))
                    } else {
                        await self.response(cancelled: !completed,
                                            result: .success(returnedItems ?? []))
                    }
                }
            }
            
            return await show(vc: vc).castError()
        }
        
        @MainActor
        public func receive() async -> Result<Data, TesseractError> {
            return await withUnsafeContinuation { cont in
                self.continuations.append(cont)
            }.castError()
        }
        
        @MainActor
        private func show(vc: UIActivityViewController) async -> Result<(), Error> {
            return await withUnsafeContinuation { cont in
                self.requests.append((vc, cont))
                if self.requests.count == 1 {
                    Task { try! await self.present().get() }
                }
            }
        }
        
        @MainActor
        private func present() async -> Result<(), Error> {
            guard let (vc, cont) = requests.first else {
                return .failure(.wrongInternalState("nothing to present"))
            }
            cont.resume(returning: await self.presenter.present(vc: vc))
            return .success(())
        }
        
        @MainActor
        private func response(cancelled: Bool, result: Result<[Any], Error>) async {
            guard let receiver = continuations.first else {
                print("Error: empty receivers")
                return
            }
            continuations.removeFirst()
            guard requests.first != nil else {
                receiver.resume(returning: .failure(.wrongInternalState("empty requests")))
                return
            }
            requests.removeFirst()
            
            switch result {
            case .failure(let error):
                receiver.resume(returning: .failure(error))
            case .success(let items):
                if cancelled {
                    receiver.resume(returning: .failure(.cancelled))
                } else {
                    let attachments = items.compactMap {$0 as? NSExtensionItem}.compactMap{$0.attachments}.flatMap{$0}
                    guard let item = attachments.first else {
                        receiver.resume(
                            returning: .failure(.emptyResponse)
                        )
                        return
                    }
                    do {
                        let result = try await item.loadItem(forTypeIdentifier: uti)
                        if let data = result as? Data {
                            receiver.resume(returning: .success(data))
                        } else {
                            receiver.resume(
                                returning: .failure(
                                    .unsupportedDataType("\(type(of: result))")
                                )
                            )
                        }
                    } catch {
                        receiver.resume(returning: .failure(.nested(error as NSError)))
                    }
                }
            }
            
            if !requests.isEmpty {
                try! await self.present().get()
            }
        }
    }
}



public extension IPCTransportIOS {
    enum Error: Swift.Error, TesseractErrorConvertible, CustomNSError {
        case cancelled
        case wrongInternalState(String)
        case wrongProtocolId(String)
        case emptyResponse
        case unsupportedDataType(String)
        case nested(NSError)
        
        public var tesseract: TesseractError {
            switch self {
            case .cancelled: return .cancelled
            case .nested(let err): return .swift(error: err)
            default: return .swift(error: self as NSError)
            }
        }
        
        /// The domain of the error.
        public static var errorDomain: String { "IPCTransportIOS.Error" }

        /// The error code within the given domain.
        public var errorCode: Int {
            switch self {
            case .cancelled: return 0
            case .wrongInternalState: return 1
            case .wrongProtocolId: return 2
            case .emptyResponse: return 3
            case .unsupportedDataType: return 4
            case .nested: return 5
            }
        }

        /// The user-info dictionary.
        public var errorUserInfo: [String : Any] {
            switch self {
            case .cancelled:
                return [NSLocalizedDescriptionKey: "Cancelled"]
            case .wrongInternalState(let reason):
                return [NSLocalizedDescriptionKey: "Bad state: \(reason)"]
            case .emptyResponse:
                return [NSLocalizedDescriptionKey: "Response is empty"]
            case .wrongProtocolId(let proto):
                return [NSLocalizedDescriptionKey: "Bad protocol id \(proto)"]
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
