//
//  ViewController.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/18/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class mainPageVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,
                    CatchHistoryListener {
    var locationManager: CLLocationManager?
    var userCatchHistory: CatchHistory?
    let networkAdaptor = NetworkModelAdaptor()
    let mainPageState = MainPageState()
    var mainPageStateObserver: NSObjectProtocol?
    let detailPageID = "detailEditingPage"   // detail editing page vc ID
    let suggestionPageID = "suggestionPage"   // suggestion page vc ID
    let myCatchPageID = "myCatchPage"         // myCatch page vc ID
    
    @IBOutlet weak var map: MKMapView!
    
    
    // user want to save a catch record
    // do two things:
    // 1. create a new default record
    // 2. grap weather data from network and store in the new record
    @IBAction func gotAFishButtonPressed(_ sender: UIButton) {
        // add new record to history
        guard let currentLocation = locationManager?.location?.coordinate else {
            print("can't get user's location!")
            return
        }
        userCatchHistory?.addDefalutItem(currentLocation: currentLocation)
        if userCatchHistory != nil {
            let row = (userCatchHistory?.numOfItemsIn(type: WaterCategory.freshWater))! - 1
            goToDetailEditingPage(section: WaterCategory.freshWater, row: row)
        }
        else {
            print("model not ready!")
            return
        }
        
        // get weather data
        getWeatherData()
        
        
    }
    
    
    @IBAction func showSuggestionButtonPressed(_ sender: UIButton) {
        gotoSuggestionPage()
    }

    @IBAction func showMyCatchButtonPressed(_ sender: Any) {
        goToCatchList()
    }
    
    override func viewDidLoad() {
        // install notification observer
        mainPageStateObserver = Center.addObserver(forName: NSNotification.Name(rawValue: Messages.dataFromNetworkArrvied), object: nil, queue: OperationQueue.main) {
            [weak self] (notification: Notification) in
            if self != nil {
                self?.updateWeatherData()
            }
        }

        setUpMapView()
        loadUserData()
        annotateCatchesOnMap()
        userCatchHistory?.delegate.append(self)
        
        super.viewDidLoad()
    }

        // set up the map view with correct location and landmarks
    func setUpMapView() {
        self.locationManager = CLLocationManager()
        self.locationManager!.requestAlwaysAuthorization()
        self.locationManager!.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager!.startUpdatingLocation()
        }
        guard let currentLocation = self.locationManager?.location?.coordinate else {
            print("Current location not available!")
            return
        }
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.2, 0.2)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(currentLocation, span)
        map.setRegion(region, animated: true)
    }
    
    func loadUserData() {
        do {
            let savedUserData = try Persistence.restore()
            print("Second run or later. Found the archived model.")
            if let userData = savedUserData as? CatchHistory {
                self.userCatchHistory = userData
                print("Successfully restored the data from disk!")
                userCatchHistory = userData
            }
            else {
                print("Got the wrong type, stop here.")
                return
            }

        }
        catch _ as NSError {
            // nothing was saved from before
            print("Probably the first run. No archived model. Will create a new one.")
            userCatchHistory = CatchHistory()
            
        }
    }
    
    
    // get weather data from network and store in the model
    func getWeatherData() -> Void {
        guard let currentLocation = locationManager?.location?.coordinate else {
            print("can't get user's location!")
            return
        }
        
        let lat = currentLocation.latitude
        let lon = currentLocation.longitude
        
        networkAdaptor.getWeatherInfo(latitude: lat, longitude: lon, theTime: nil) {
            [weak self] (possibleWeatherData, possibleError) in
            // We're not on the UI thread...we're on ONE OF SEVERAL network threads
            print("Am I on main (better be no): \(Thread.isMainThread)")
            // Not allowed to manipulate UI right now
            OperationQueue.main.addOperation {
                // Not much control over when this runs
                // But it will run very soon, mandate of Event queue
                guard self != nil else {
                    return
                }
                guard let theWeatherData = possibleWeatherData else {
                    print("Failed to get the data")
                    return
                }
                // got the data. Store in the mainpage state object
                self?.mainPageState.weather = theWeatherData
                // print(theWeatherData)
            }
        }
        
        networkAdaptor.getTideInfo(latitude: lat, longitude: lon, start: nil, length: nil, step: nil) {
            [weak self] (possibleTideData, possibleError) in
            // We're not on the UI thread...we're on ONE OF SEVERAL network threads
            print("Am I on main (better be no): \(Thread.isMainThread)")
            // Not allowed to manipulate UI right now
            OperationQueue.main.addOperation {
                // Not much control over when this runs
                // But it will run very soon, mandate of Event queue
                guard self != nil else {
                    return
                }
                guard let theTideData = possibleTideData else {
                    print("Failed to get the data")
                    return
                }
                // got the data now write to the model
                self?.mainPageState.tide = theTideData
                // print(theTideData)
            }
        }
    }
    
    
    
    // update model if all weather data are ready
    // here we always update the newly created one
    func updateWeatherData() {
        if let weatherData = mainPageState.weather, let tideData = mainPageState.tide {
            let weather = self.builWeatherData(Weather: weatherData, tide: tideData)
            let row = (userCatchHistory?.numOfItemsIn(type: WaterCategory.freshWater))! - 1
            userCatchHistory?.updateWeatherDataAt(at: row, type: WaterCategory.freshWater, weatherDataToSave: weather)
        }
        else {
            print("weather data not ready yet!")
        }
    }
    
    
    
    
    // creat and return weatherData object
    func builWeatherData(Weather: NSDictionary, tide: NSDictionary) -> WeatherData {
        let currentWeather = Weather["currently"] as! NSDictionary
        let tideHeightdData = tide["heights"] as! [NSDictionary]
        
        let time = Int64(currentWeather["time"] as! NSNumber)
        let summary = currentWeather["summary"] as! String
        let temperature = Double(currentWeather["temperature"] as! NSNumber)
        let cloudCover = Double(currentWeather["cloudCover"] as! NSNumber)
        let windBearing = Int(currentWeather["windBearing"] as! NSNumber)
        let windSpeed = Double(currentWeather["windSpeed"] as! NSNumber)
        let pressure = Double(currentWeather["pressure"] as! NSNumber)
        

        let tideHeight = Double(tideHeightdData[13]["height"] as! NSNumber)
        
        let theWeatherData = WeatherData(theTime: time, theSummary: summary, theTemperature: temperature, theCloudCover: cloudCover, theWindBearing: windBearing, theWindSpeed: windSpeed, thePressure: pressure, theTidalHeight: tideHeight)
        
        return theWeatherData
    }
    
    
    
    
    // annotate catch record on the map
    func annotateCatchesOnMap() {
        guard let records = userCatchHistory else {
            print("data is not available")
            return
        }
        // clear previous annotations
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        // add new annotations
        records.catchHistory.forEach { record in
            let annotation = MKPointAnnotation()
            let location = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
            annotation.coordinate = location
            annotation.title = record.species
            map.addAnnotation(annotation)
        }
    }
    
    
    
    
    // comfort catchhistory listener protocol
    func catchHistoryChanged() {
        annotateCatchesOnMap()
    }

    
    // sague to detail editing page for editing certain record
    private func goToDetailEditingPage(section: WaterCategory, row: Int) {
        // create the new View
        guard let detailPage = UIStoryboard.makeVC(detailPageID) as? DetailEditingVC else {
            print("Can't find the right detailEditing page VC!")
            return
        }
        
        
        // pass the record to edit
        let itemToEdit = userCatchHistory?.itemAtIndexOfType(at: row, type: section)
        detailPage.catchRecord = itemToEdit
        
        
        // set up call back when user tapped save button
        detailPage.saveChangeToItem = { (picture: UIImage, species: Species,
            weight: Double, bait: String, waterType: WaterCategory) -> Void in
            self.userCatchHistory?.updateItemAt(at: row, type: section, picture: picture, species: species, weight: weight, bait: bait, waterType: waterType)
            print("number of records: \(self.userCatchHistory!.catchHistory.count)")
            
        }
        
        // set up call back when user tapped back button
        // in this case, if editing existing record, do nothing, 
        // if new default item remove the new default item
        detailPage.cancelEditing = { () -> Void in
            if itemToEdit?.weight == 0.0 {  // new default item
                self.userCatchHistory?.removeItemAt(at: row, type: section)
                print("default new itme was deleted")
                 print("number of records: \(self.userCatchHistory!.catchHistory.count)")
            }
            else {   // existing item
                // do nothing
            }
        }
        
        // push the VC to screen
        navigationController?.pushViewController(detailPage, animated: true)
    }
    
    // sague to go to catch list (tab bar controller)
    private func goToCatchList() {
        // create the catch list tab bar view
        guard let catchListPage = UIStoryboard.makeVC(myCatchPageID) as? CatchListTabBarVC else {
            print("Can't find the right my catch page VC!")
            return
        }
        
        // pass data to it
        catchListPage.catchHistory = self.userCatchHistory
        
        
        // push the VC to screen
        navigationController?.pushViewController(catchListPage, animated: true)
        
    }
    
    // sague to suggestion page
    // sague to go to catch list (tab bar controller)
    private func gotoSuggestionPage() {
        // create the catch list tab bar view
        guard let suggestionPage = UIStoryboard.makeVC(suggestionPageID) as? SuggestionVC else {
            print("Can't find the right my catch page VC!")
            return
        }
        
        // pass data to it
        suggestionPage.bestForFreshWater = userCatchHistory?.bestConditionForFreshWater
        suggestionPage.bestForSaltWater = userCatchHistory?.bestConditionForSaltWater
        
        
        // push the VC to screen
        navigationController?.pushViewController(suggestionPage, animated: true)
        
    }
    
}

