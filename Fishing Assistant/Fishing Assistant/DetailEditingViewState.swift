//
//  DetailEditingViewState.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/30/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit

// state model for detail editting page

class DetailEditingViewState {
    var picture: UIImage? {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: Messages.detailEditingViewStateChanged), object: self)
            NotificationCenter.default.post(notification)
        }
    }
    var species: Species = Species.striper {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: Messages.detailEditingViewStateChanged), object: self)
            NotificationCenter.default.post(notification)
        }
    }
    var weight = ""
    var bait = ""
    var waterType: WaterCategory? {
        didSet {
            let notification = Notification(name: Notification.Name(rawValue: Messages.detailEditingViewStateChanged), object: self)
            NotificationCenter.default.post(notification)
        }
    }
    
}
