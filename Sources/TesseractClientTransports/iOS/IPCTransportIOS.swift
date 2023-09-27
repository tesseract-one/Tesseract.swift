//
//  IPCTransportIOS.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit
import TesseractShared

public protocol ViewControllerPresenter {
    func present(vc: UIViewController) async throws
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
    public func present(vc: UIViewController) async throws {
        return try await withUnsafeThrowingContinuation { cont in
            guard let rootView = self.rootViewController else {
                cont.resume(throwing: CError.wrongInternalState(message: "Empty root view"))
                return
            }
            let controller = rootView.presentedViewController ?? rootView
            controller.present(vc, animated: true) {
                cont.resume(returning: ())
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
    private var requests: Array<(UIActivityViewController, UnsafeContinuation<Void, Error>)>
    private var continuations: Array<UnsafeContinuation<Data, Error>>
    
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
    public func send(request: Data) async throws {
        let vc = UIActivityViewController(
            activityItems: [ActivityItemSource(data: request, uti: uti)],
            applicationActivities: nil
        )
        
        vc.excludedActivityTypes = UIActivity.ActivityType.all
        
        vc.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            Task {
                if let error = error {
                    await self.response(cancelled: !completed, result: .failure(error))
                } else {
                    await self.response(cancelled: !completed, result: .success(returnedItems ?? []))
                }
            }
        }
        
        return try await show(vc: vc)
    }
    
    @MainActor
    public func receive() async throws -> Data {
        return try await withUnsafeThrowingContinuation { cont in
            self.continuations.append(cont)
        }
    }
    
    @MainActor
    private func show(vc: UIActivityViewController) async throws {
        return try await withUnsafeThrowingContinuation { cont in
            self.requests.append((vc, cont))
            if self.requests.count == 1 {
                Task { try! await self.present() }
            }
        }
    }
    
    @MainActor
    private func present() async throws {
        guard let (vc, cont) = requests.first else {
            throw CError.panic(reason: "Nothing to present")
        }
        do {
            try await self.presenter.present(vc: vc)
            cont.resume(returning: ())
        } catch {
            cont.resume(throwing: error)
        }
    }
    
    @MainActor
    private func response(cancelled: Bool, result: Result<[Any], Error>) async {
        guard let receiver = continuations.first else {
            print("Error: empty receivers")
            return
        }
        continuations.removeFirst()
        guard requests.first != nil else {
            receiver.resume(throwing: CError.wrongInternalState(message: "Empty requests"))
            return
        }
        requests.removeFirst()
        
        switch result {
        case .failure(let error):
            receiver.resume(throwing: error)
        case .success(let items):
            if cancelled {
                receiver.resume(throwing: CError.canceled)
            } else {
                let attachments = items.compactMap {$0 as? NSExtensionItem}.compactMap{$0.attachments}.flatMap{$0}
                guard let item = attachments.first else {
                    receiver.resume(
                        throwing: CError.emptyResponse(message: "Attachment is not returned")
                    )
                    return
                }
                do {
                    let result = try await item.loadItem(forTypeIdentifier: uti)
                    if let data = result as? Data {
                        receiver.resume(returning: data)
                    } else {
                        receiver.resume(
                            throwing: CError.unsupportedDataType(message: "Bad response: \(result)")
                        )
                    }
                } catch {
                    receiver.resume(throwing: error)
                }
            }
        }
        
        if !requests.isEmpty {
            try! await self.present()
        }
    }
}
