//
//  IPCTransportIOS.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import TesseractShared

public protocol ViewControllerPresenter {
    func present(vc: UIViewController) async -> Result<(), CError>
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
    public func present(vc: UIViewController) async -> Result<(), CError> {
        return await withUnsafeContinuation { cont in
            guard let rootView = self.rootViewController else {
                cont.resume(
                    returning: .failure(.wrongInternalState(message: "Empty root view"))
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
            return .error(.wrongProtocolId(message: "Bad protocol: \(proto)"))
        }
        if await UIApplication.shared.canOpenURL(url) {
            return .ready
        } else {
            return .unavailable("Wallet is not installed")
        }
    }
    
    public func connect(proto: String) -> Connection {
        IPCTransportIOSConnection(proto: proto, presenter: presenter)
    }
    
    public static func url(proto: String) -> URL? {
        URL(string: "tesseract+\(proto)://")
    }
}

public class IPCTransportIOSConnection: Connection {
    private var requests: Array<(UIActivityViewController,
                                 UnsafeContinuation<Result<(), CError>, Never>)>
    private var continuations: Array<UnsafeContinuation<Result<Data, CError>, Never>>
    
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
    public func send(request: Data) async -> Result<(), CError> {
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
                                        result: .failure(.nested(error: error)))
                } else {
                    await self.response(cancelled: !completed,
                                        result: .success(returnedItems ?? []))
                }
            }
        }
        
        return await show(vc: vc)
    }
    
    @MainActor
    public func receive() async -> Result<Data, CError> {
        return await withUnsafeContinuation { cont in
            self.continuations.append(cont)
        }
    }
    
    @MainActor
    private func show(vc: UIActivityViewController) async -> Result<(), CError> {
        return await withUnsafeContinuation { cont in
            self.requests.append((vc, cont))
            if self.requests.count == 1 {
                Task { try! await self.present().get() }
            }
        }
    }
    
    @MainActor
    private func present() async -> Result<(), CError> {
        guard let (vc, cont) = requests.first else {
            return .failure(.panic(reason: "Nothing to present"))
        }
        cont.resume(returning: await self.presenter.present(vc: vc))
        return .success(())
    }
    
    @MainActor
    private func response(cancelled: Bool, result: Result<[Any], CError>) async {
        guard let receiver = continuations.first else {
            print("Error: empty receivers")
            return
        }
        continuations.removeFirst()
        guard requests.first != nil else {
            receiver.resume(returning: .failure(.wrongInternalState(message: "Empty requests")))
            return
        }
        requests.removeFirst()
        
        switch result {
        case .failure(let error):
            receiver.resume(returning: .failure(error))
        case .success(let items):
            if cancelled {
                receiver.resume(returning: .failure(.canceled))
            } else {
                let attachments = items.compactMap {$0 as? NSExtensionItem}.compactMap{$0.attachments}.flatMap{$0}
                guard let item = attachments.first else {
                    receiver.resume(
                        returning: .failure(
                            .emptyResponse(message: "Attachment is not returned")
                        )
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
                                .unsupportedDataType(message: "Bad response: \(result)")
                            )
                        )
                    }
                } catch {
                    receiver.resume(returning: .failure(.nested(error: error)))
                }
            }
        }
        
        if !requests.isEmpty {
            try! await self.present().get()
        }
    }
}
