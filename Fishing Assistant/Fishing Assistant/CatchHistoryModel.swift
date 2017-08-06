//
//  CatchHistoryModel.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit
import MapKit


// in order to store the enums to disk, have to assign raw value to each one
// and store the raw value in class and on disk
enum WaterCategory: String {
    case saltWater      = "Saltwater"
    case freshWater     = "Freshwater"
}

enum Species: String {
    case striper        = "Striper"
    case bigMouse       = "Big Mouse"
    case blueGill       = "Bluegill"
    case catfish        = "Catfish"
    case smallMouth     = "Small Mouth"
    case gar            = "Gar"
    case cap            = "Cap"
    
    // get enum by index
    static func getValueByIndex(index: Int) -> Species {
        switch index {
        case 0: return Species.striper
        case 1: return Species.bigMouse
        case 2: return Species.blueGill
        case 3: return Species.catfish
        case 4: return Species.smallMouth
        case 5: return Species.gar
        case 6: return Species.cap
        default: return Species.striper
        }
    }
    
    // get index by enum
    static func getIndexByEnum(thevalue: Species) -> Int {
        switch thevalue {
        case .striper: return 0
        case .bigMouse: return 1
        case .blueGill: return 2
        case .catfish: return 3
        case .smallMouth: return 4
        case .gar: return 5
        case .cap: return 6
        }
    }
    
    
    // get the total number of items in this enum
    // ugly but works for the moment
    static func count() -> Int{
        return 7
    }
}


// segment data for suggestion
enum TimeSection: String {
    case earlyMorning   = "Early morning"
    case lateMorning    = "Late morning"
    case noon           = "Noon"
    case earlyAfternoon = "Early afternoon"
    case lateAfternoon  = "Late afternoon"
    case atDusk         = "At dusk"
}

enum TemperatureSection: String {
    case colderThan50   = "Colder than 50 degrees"
    case In50s          = "50 - 60 degrees"
    case In60s          = "60 - 70 degrees"
    case In70s          = "70 - 80 degrees"
    case In80s          = "80 - 90 degrees"
    case In90s          = "90 - 100 degrees"
    case above90s       = "Crazy hot than 90 degrees"
}


enum WeatherSummarySection: String {
    case Sunny          = "Sunny"
    case Cloudy         = "Cloudy"
    case raining        = "Raining"
    case snowing        = "snowing"
    case NA             = "N.A."
}

enum TideHeightSection: String {
    case low            = "< 3 feet"
    case midLow         = "3 - 6 feet"
    case mid            = "6 - 8 feet"
    case midHigh        = "8 - 10 feet"
    case high           = "> 10 feet"
}


// for passing to suggestion view
struct BestCondition {
    var temp: String?
    var time: String?
    var tide: String?
    var weather: String?
    var mostCatch: String?
    
}



// for sorting result
enum SortBy {
    case date
    case weight
    case species
}



// I would like to use structs here but unfortunately struct is not supported by NSCoding
// So I have to change them all to helper classes, otherwise lot more code need to be added...
class WeatherData: NSObject, NSCoding {
    var time: Int64   // epoch time
    var summary: String
    var temperature: Double
    var cloudCover: Double
    var windBearing: Int
    var windSpeed: Double
    var pressure: Double
    var tidalHeight: Double
    

    init(theTime: Int64, theSummary: String, theTemperature: Double, theCloudCover: Double,
                  theWindBearing: Int, theWindSpeed: Double, thePressure: Double, theTidalHeight: Double) {
        time = theTime
        summary = theSummary
        temperature = theTemperature
        cloudCover = theCloudCover
        windBearing = theWindBearing
        windSpeed = theWindSpeed
        pressure = thePressure
        tidalHeight = theTidalHeight
        
        super.init()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        time = aDecoder.decodeInt64(forKey: "time")
        summary = aDecoder.decodeObject(forKey: "summary") as! String
        temperature = aDecoder.decodeDouble(forKey: "temperature")
        cloudCover = aDecoder.decodeDouble(forKey: "cloudCover")
        windBearing = Int(aDecoder.decodeInt32(forKey: "windBearing"))
        windSpeed = aDecoder.decodeDouble(forKey: "windSpeed")
        pressure = aDecoder.decodeDouble(forKey: "pressure")
        tidalHeight = aDecoder.decodeDouble(forKey: "tidalHeight")
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: "time")
        aCoder.encode(summary, forKey: "summary")
        aCoder.encode(temperature, forKey: "temperature")
        aCoder.encode(cloudCover, forKey: "cloudCover")
        aCoder.encode(windBearing, forKey: "windBearing")
        aCoder.encode(windSpeed, forKey: "windSpeed")
        aCoder.encode(pressure, forKey: "pressure")
        aCoder.encode(tidalHeight, forKey: "tidalHeight")
    }

}


class AbstractedWeatherData: NSObject, NSCoding {
    var timeSection: TimeSection.RawValue
    var temperatureSection: TemperatureSection.RawValue
    var weatherSummarySection: WeatherSummarySection.RawValue
    var tideHeightSection: TideHeightSection.RawValue
    
    // build abstracted weatherData from weather data
    init(time: TimeSection, temperature: TemperatureSection,
         weatherSum: WeatherSummarySection, tideHeight: TideHeightSection) {
        timeSection = time.rawValue
        temperatureSection = temperature.rawValue
        weatherSummarySection = weatherSum.rawValue
        tideHeightSection = tideHeight.rawValue
        
        super.init()
    }
    
    
    // for data persistence on disk
    required init?(coder aDecoder: NSCoder) {
        timeSection = aDecoder.decodeObject(forKey: "timeSection") as! TimeSection.RawValue
        temperatureSection = aDecoder.decodeObject(forKey: "temperatureSection") as! TemperatureSection.RawValue
        weatherSummarySection = aDecoder.decodeObject(forKey: "weatherSummary") as! WeatherSummarySection.RawValue
        tideHeightSection = aDecoder.decodeObject(forKey: "tideHeightSection") as! TideHeightSection.RawValue
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(timeSection, forKey: "timeSection")
        aCoder.encode(temperatureSection, forKey: "temperatureSection")
        aCoder.encode(weatherSummarySection, forKey: "weatherSummary")
        aCoder.encode(tideHeightSection, forKey: "tideHeightSection")
    }
    
}


class CatchRecord: NSObject, NSCoding {
    var timeStamp: Int64  // epoch time
    var picture: UIImage?
    var species: Species.RawValue
    var weight: Double
    var bait: String
    var waterType: WaterCategory.RawValue
    
    var latitude: Double
    var longitude: Double
    var weather: WeatherData?
    var groupedDataForSuggestion: AbstractedWeatherData?
    
    init(theTime: Int64, thePicture: UIImage?, theSpecies: Species.RawValue, theWeight: Double,
         theBait: String, theWaterType: WaterCategory.RawValue, theLatitude: Double,
         theLongitude: Double, theWeather: WeatherData?,
         theGroupedDataForSuggestion: AbstractedWeatherData?) {
        timeStamp = theTime
        picture = thePicture
        species = theSpecies
        weight = theWeight
        bait = theBait
        waterType = theWaterType
        latitude = theLatitude
        longitude = theLongitude
        super.init()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        timeStamp = aDecoder.decodeInt64(forKey: "timeStamp")
        picture = aDecoder.decodeObject(forKey: "picture") as? UIImage
        species = aDecoder.decodeObject(forKey: "species") as! Species.RawValue
        weight = aDecoder.decodeDouble(forKey: "weight")
        bait = aDecoder.decodeObject(forKey: "bait") as! String
        waterType = aDecoder.decodeObject(forKey: "waterType") as! WaterCategory.RawValue
        
        latitude = aDecoder.decodeDouble(forKey: "latitude")
        longitude = aDecoder.decodeDouble(forKey: "longitude")
        weather = aDecoder.decodeObject(forKey: "weather") as? WeatherData
        groupedDataForSuggestion = aDecoder.decodeObject(forKey: "groupedDataForSuggestion") as? AbstractedWeatherData

    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(timeStamp, forKey: "timeStamp")
        aCoder.encode(picture, forKey: "picture")
        aCoder.encode(species, forKey: "species")
        aCoder.encode(weight, forKey: "weight")
        aCoder.encode(bait, forKey: "bait")
        aCoder.encode(waterType, forKey: "waterType")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(weather, forKey: "weather")
        aCoder.encode(groupedDataForSuggestion, forKey: "groupedDataForSuggestion")
    }
    
}


// the root class save onto disk

class CatchHistory: NSObject, EventLogDataSource, NSCoding {
    let newItemDefaultName = "new fish"   // used to create default new item
    
    var catchHistory: [CatchRecord]
    var delegate: [CatchHistoryListener] = []
    
    
    // calculated properties for suggestions
    var bestConditionForFreshWater: BestCondition  {
        get {
            return theBestConditionFor(waterType: WaterCategory.freshWater)
        }
    }
    
    var bestConditionForSaltWater: BestCondition  {
        get {
            return theBestConditionFor(waterType: WaterCategory.saltWater)
        }
    }
    
    
    
    
    
    // ***************************
    // necessary functions to enable data store to disk
    override init() {
        catchHistory = [CatchRecord]()  // start with an empty array
        
        super.init()
    }
 
    required init?(coder aDecoder: NSCoder) {
        catchHistory = aDecoder.decodeObject(forKey: "catchHistory") as! [CatchRecord]
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(catchHistory, forKey: "catchHistory")
    }
    
    
    // ***************************
    // functions to do the work
    func numOfItemsIn(type: WaterCategory) -> Int {
        return catchHistory.filter{$0.waterType == type.rawValue}.count
    }
    
    func itemsIn(type: WaterCategory) -> [CatchRecord] {
        return catchHistory.filter{$0.waterType == type.rawValue}
    }
    
    func itemAtIndexOfType(at index: Int, type: WaterCategory) -> CatchRecord {
        return catchHistory.filter{$0.waterType == type.rawValue}[index]
    }
    
    // add default new item
    // by defualt add in freshwater category
    // the mark of new item is the weight: 0.0 is not allowed when saving item
    func addDefalutItem(currentLocation: CLLocationCoordinate2D) -> Void {
        let latitude = currentLocation.latitude
        let longitude = currentLocation.longitude
        let currentTime = Int64(NSDate().timeIntervalSince1970)
        
        let newItem = CatchRecord(theTime: currentTime, thePicture: nil,
                                  theSpecies: Species.bigMouse.rawValue, theWeight: 0.0,
                                  theBait: "", theWaterType: WaterCategory.freshWater.rawValue,
                                  theLatitude: latitude, theLongitude: longitude,
                                  theWeather: nil, theGroupedDataForSuggestion: nil)
        catchHistory.append(newItem)
        for listener in delegate {
            listener.catchHistoryChanged()
        }
    }
    
    // the method called when user edited the catch record
    // only care about user specified data
    func updateItemAt(at index: Int, type: WaterCategory, picture: UIImage,
                      species: Species, weight: Double, bait: String, waterType: WaterCategory) -> Void {
        var curIndex = 0
        
        for i in 0..<catchHistory.count {
            if catchHistory[i].waterType == type.rawValue {   // type matched
                if curIndex == index {  // index matched
                    catchHistory[i].picture = picture
                    catchHistory[i].species = species.rawValue
                    catchHistory[i].weight = weight
                    catchHistory[i].bait = bait
                    catchHistory[i].waterType = waterType.rawValue

                    //report the change event
                    saveRecords()
                    for listener in delegate {
                        listener.catchHistoryChanged()
                    }
                    return
                }
                else {
                    curIndex += 1
                }
            }
        }
        
        print("Item did not found!")
    }
    
    
    // the method called when we save weather data from network
    func updateWeatherDataAt(at index: Int, type: WaterCategory, weatherDataToSave: WeatherData) -> Void {
        var curIndex = 0
        
        for i in 0..<catchHistory.count {
            if catchHistory[i].waterType == type.rawValue {   // type matched
                if curIndex == index {  // index matched
                    catchHistory[i].weather = weatherDataToSave
                    catchHistory[i].groupedDataForSuggestion = buildGroupedDataForSuggestion(weather: weatherDataToSave)

                    //report the change event
                    saveRecords()
                    for listener in delegate {
                        listener.catchHistoryChanged()
                    }
                    return
                }
                else {
                    curIndex += 1
                }
            }
        }
        print("Item did not found!")
    }
    
    // helper functions to build abstracted weather info
    
    
    private func buildGroupedDataForSuggestion(weather: WeatherData) -> AbstractedWeatherData {
        let time = getTimeSection(epochTime: weather.time)
        let temperature = getTemperatureSection(temperature: weather.temperature)
        let weatherSum = getSummarySection(weatherSummary: weather.summary)
        let tideHeight = getTideSection(tideHeight: weather.tidalHeight)
        
        return AbstractedWeatherData(time: time, temperature: temperature, weatherSum: weatherSum, tideHeight: tideHeight)
    }
    

    
    
    private func getTimeSection(epochTime: Int64) -> TimeSection {
        let date: Date = NSDate(timeIntervalSince1970: TimeInterval(epochTime)) as Date
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 0...8: return TimeSection.earlyMorning
        case 9...11: return TimeSection.lateMorning
        case 11...12: return TimeSection.noon
        case 13...14: return TimeSection.earlyAfternoon
        case 15...17: return TimeSection.lateAfternoon
        case 18...23: return TimeSection.atDusk
        default: return TimeSection.earlyMorning
        }
    }
    
    private func getTemperatureSection(temperature: Double) -> TemperatureSection {
        switch temperature {
        case -100.0...49.9: return TemperatureSection.colderThan50
        case 50.0...59.9: return TemperatureSection.In50s
        case 60.0...69.9: return TemperatureSection.In60s
        case 70.0...79.9: return TemperatureSection.In70s
        case 80.0...89.9: return TemperatureSection.In80s
        case 90.0...99.9: return TemperatureSection.In90s
        case 100.0...200: return TemperatureSection.above90s
        default: return TemperatureSection.colderThan50
        }
    }
    
    private func getTideSection(tideHeight: Double) -> TideHeightSection {
        // convert from meters to feet
        let height = tideHeight * 3.28084
        switch height {
        case -100.0...2.99: return TideHeightSection.low
        case 3.0...5.99: return TideHeightSection.midLow
        case 6.0...7.99: return TideHeightSection.mid
        case 8.0...9.99: return TideHeightSection.midHigh
        case 10.0...100: return TideHeightSection.high
        default: return TideHeightSection.high  // should never happened unless the day after tomorrow happens
        }
    }
    
    
    
    
    private func getSummarySection(weatherSummary: String) -> WeatherSummarySection {
        if weatherSummary.lowercased().range(of: "sunny") != nil ||
            weatherSummary.lowercased().range(of: "clear") != nil {
            return WeatherSummarySection.Sunny
        }
        if weatherSummary.lowercased().range(of: "cloud") != nil {
            return WeatherSummarySection.Cloudy
        }
        if weatherSummary.lowercased().range(of: "rain") != nil ||
            weatherSummary.lowercased().range(of: "shower") != nil ||
            weatherSummary.lowercased().range(of: "thunder") != nil {
            return WeatherSummarySection.raining
        }
        if weatherSummary.lowercased().range(of: "snow") != nil {
            return WeatherSummarySection.snowing
        }
        return WeatherSummarySection.NA
    }
    

    func removeItemAt(at index: Int, type: WaterCategory)-> Void {
        var curIndex = 0
        for i in 0..<catchHistory.count {
            if catchHistory[i].waterType == type.rawValue {   // type matched
                if curIndex == index {  // index matched
                    catchHistory.remove(at: i)
                    
                    // need to broadcast the change
                    saveRecords()
                    for listener in delegate {
                        listener.catchHistoryChanged()
                    }
                    return
                }
                else {
                    curIndex += 1
                }
            }
        }
        print ("Item did not found!")
    }
    
    
    // get records sorted by certain criteria
    func itemsSortByDate() -> Void {
        catchHistory = catchHistory.sorted(by: {(catchRecord0, catchRecord1) -> Bool in
            catchRecord0.timeStamp > catchRecord1.timeStamp
        })
        for listener in delegate {
            listener.catchHistoryChanged()
        }
    }
    
    
    func itemsSortByWeight() -> Void {
        catchHistory = catchHistory.sorted(by: {(catchRecord0, catchRecord1) -> Bool in
            catchRecord0.weight > catchRecord1.weight
        })
        for listener in delegate {
            listener.catchHistoryChanged()
        }
    }
    
    
    func itemsSortBySpecies() -> Void {
        catchHistory = catchHistory.sorted(by: {(catchRecord0, catchRecord1) -> Bool in
            catchRecord0.species > catchRecord1.species
        })
        for listener in delegate {
            listener.catchHistoryChanged()
        }
    }
    
    
    // get the best condition as suggestion
    private func theBestConditionFor(waterType: WaterCategory) -> BestCondition {
        let bestTime = mostFrequentOf(param: TimeSection.earlyMorning, at: waterType)
        let bestTemp = mostFrequentOf(param: TemperatureSection.In50s, at: waterType)
        let bestWeather = mostFrequentOf(param: WeatherSummarySection.Sunny, at: waterType)
        let bestTide = mostFrequentOf(param: TideHeightSection.low, at: waterType)
        let mostCatch = mostFrequentOf(param: Species.bigMouse, at: waterType)
        
        return BestCondition(temp: bestTemp, time: bestTime, tide: bestTide, weather: bestWeather, mostCatch: mostCatch)
    }
    
    
    
    // get the most frequent weather codition from catch history
    // for param, only care about the type, not the value
    private func mostFrequentOf(param: Any, at: WaterCategory) -> String {
        var targetPropertyArray: [String] = []
        var frequencyTable: [String: Int] = [:]
        
        let targetHistory = catchHistory.filter { $0.waterType == at.rawValue}
        
        
        // get the data array
        switch param {
        case _ as TimeSection:
            targetPropertyArray = targetHistory.map{(item) in
                if let theTime = item.groupedDataForSuggestion?.timeSection {
                    return theTime
                }
                return ""
            }
        case _ as TemperatureSection:
            targetPropertyArray = targetHistory.map{(item) in
                if let theTemp = item.groupedDataForSuggestion?.temperatureSection {
                    return theTemp
                }
                return ""
            }
        case _ as WeatherSummarySection:
            targetPropertyArray = targetHistory.map{(item) in
                if let weatherSummary = item.groupedDataForSuggestion?.weatherSummarySection {
                    return weatherSummary
                }
                return ""
            }
        case _ as TideHeightSection:
            targetPropertyArray = targetHistory.map{(item) in
                if let theHeight = item.groupedDataForSuggestion?.tideHeightSection {
                    return theHeight
                }
                return ""
            }
        case _ as Species:
            targetPropertyArray = targetHistory.map{(item) in
                item.species
            }
            
        default: break // do nothing
        }
        
        // count frequency
        for item in targetPropertyArray {
            frequencyTable[item] = (frequencyTable[item] ?? 0) + 1
        }
        
        // get the most frequent one
        var maxFreq = 0
        var mostFreqItem = ""
        for (key, val) in frequencyTable {
            if val > maxFreq {
                maxFreq = val
                mostFreqItem = key
            }
        }
        return mostFreqItem
    }
    
    
    
    
    // save change to disk.
    // it was called when user save any changes on any catch record
    private func saveRecords() {
        do {
            print("attempting to save: the records...")
            try Persistence.save(self)
        }
        catch let nseInner as NSError {
            print("Failure: \(nseInner.localizedDescription)")
        }
    }
    
    
}




