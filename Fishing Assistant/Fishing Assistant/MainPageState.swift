//
//  mainPageState.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/30/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation

class MainPageState {
    // store the index info of the catch record
    var section: Int = 0
    var row: Int = 0
    
    var weather: NSDictionary?  {   // weather data from network
        didSet{
            let notification = Notification(name: Notification.Name(rawValue: Messages.dataFromNetworkArrvied), object: self)
            NotificationCenter.default.post(notification)
        }
    }
    var tide: NSDictionary?     {  // tide data from network
        didSet{
            let notification = Notification(name: Notification.Name(rawValue: Messages.dataFromNetworkArrvied), object: self)
            NotificationCenter.default.post(notification)
        }
    }
    
    
    
    
    
}
