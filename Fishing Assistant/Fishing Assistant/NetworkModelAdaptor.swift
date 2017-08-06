//
//  NetworkModelAdaptor.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/30/17.
//  Copyright © 2017 litao chen. All rights reserved.
//


// a class to handle network request to get JSON data
// some code is from lecture sample code

import Foundation
import AFNetworking
import SwiftyJSON

// APIs endpoint with key for weather data
let weatherAPIEndpoint = "https://api.darksky.net/forecast/e2f07239f7a25e3fd9a509c39dbc8d10/"

let tidalAPIEndpoint = "https://www.worldtides.info/api?key=cf835185-927e-446e-b035-fa7418d2475f"


class NetworkModelAdaptor {
    private let manager = AFHTTPSessionManager()
    
    
    
    // get the weather in the form of JSON object and run the callback
    // can be used to query current or historical weather data
    // query format:
    // https://api.darksky.net/forecast/0123456789abcdef9876543210fedcba/42.3601,-71.0589,409467600
    func getWeatherInfo(latitude: Double, longitude: Double,
            theTime: Int64?, _ resultCallback: @escaping (_ Data: NSDictionary?, _ errMsg: String?)->Void ) {
        
        var requestURL: String
        if let time = theTime {
            requestURL = "\(weatherAPIEndpoint)\(latitude),\(longitude),\(time)"
        }
        else {
            requestURL = "\(weatherAPIEndpoint)\(latitude),\(longitude)"
        }
        
        
        // network request to get the data and run the callback
        manager.get(requestURL, parameters: nil, progress: nil,
            success: { (task, result) in
                let theWeatherData = result as! NSDictionary
              resultCallback(theWeatherData, nil)
        },
            failure: { (task, error) in
                print("Error: \(error.localizedDescription)")
                resultCallback(nil, error.localizedDescription)
        })
    }
    
    
    // get the tide info in the form of JSON object and run the callback
    // query format:
    // https://www.worldtides.info/api?heights&lat=42.252877&lon=-71.002270&start=1412272800000&length=43200000&step=1800000&key=3d8b4d3e-1ee4-425a-a84d-bd0e64fbcabe
    func getTideInfo(latitude: Double, longitude: Double, start: Int64?, length: Int64?, step: Int?,
                         _ resultCallback: @escaping (_ Data: NSDictionary?, _ errMsg: String?)->Void ) {
        
        
        var params: [String: String]
        if start == nil {
            params = ["heights": "", "datum": "MLLW", "lat": String(latitude), "lon": String(longitude)]
        }
        else {
            params = ["heights": "", "datum": "MLLW", "lat": String(latitude), "lon": String(longitude),
                      "start": String(describing: start), "length": String(describing: length), "step": String(describing: step)]
        }
        
        // network request to get the data and run the callback
        manager.get(tidalAPIEndpoint, parameters: params, progress: nil,
            success: { (task, result) in
                let theTidalData = result as! NSDictionary
                resultCallback(theTidalData, nil)
        },
            failure: { (task, error) in
                resultCallback(nil, error.localizedDescription)
        })
    }
    
    
    
    
    
    
}
