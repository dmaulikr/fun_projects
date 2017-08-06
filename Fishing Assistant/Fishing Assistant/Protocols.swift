//
//  Protocols.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import MapKit


// protocol for datasource
protocol EventLogDataSource {
    func numOfItemsIn(type: WaterCategory) -> Int
    func itemsIn(type: WaterCategory) -> [CatchRecord]
    func itemAtIndexOfType(at index: Int, type: WaterCategory) -> CatchRecord
    func addDefalutItem(currentLocation: CLLocationCoordinate2D) -> Void
    func updateItemAt(at index: Int, type: WaterCategory, picture: UIImage,
                      species: Species, weight: Double, bait: String, waterType: WaterCategory) -> Void
    func updateWeatherDataAt(at index: Int, type: WaterCategory, weatherDataToSave: WeatherData) -> Void
    func removeItemAt(at index: Int, type: WaterCategory)-> Void
    
    func itemsSortByDate() -> Void
    func itemsSortByWeight() -> Void
    func itemsSortBySpecies() -> Void
    
}

// protocol for datasource delegate
protocol CatchHistoryListener {
    func catchHistoryChanged() -> Void
}





