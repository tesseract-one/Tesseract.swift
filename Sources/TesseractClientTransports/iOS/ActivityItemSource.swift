//
//  ActivityItemSource.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit

@objc public class ActivityItemSource: NSObject, UIActivityItemSource {
    public let data: Data
    public let uti: String
    
    public init(data: Data, uti: String) {
        self.data = data
        self.uti = uti
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return NSData()
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return data as NSData
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return uti
    }
}
