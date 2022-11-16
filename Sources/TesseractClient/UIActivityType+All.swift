//
//  UIActivityType+All.swift
//  TestApp
//
//  Created by Yehor Popovych on 06.10.2022.
//

import UIKit

extension UIActivity.ActivityType {
    public static let all: [UIActivity.ActivityType] = {
        var types: [UIActivity.ActivityType] = [
            .addToReadingList, .airDrop, .assignToContact, .copyToPasteboard,
            .copyToPasteboard, .mail, .message, .openInIBooks,
            .postToFacebook, .postToFlickr, .postToTencentWeibo, .postToTwitter,
            .postToVimeo, .postToWeibo, .print, .saveToCameraRoll, .markupAsPDF
        ]
        if #available(iOS 15.4, *) {
            types.append(.sharePlay)
        }
        return types
    }()
}
