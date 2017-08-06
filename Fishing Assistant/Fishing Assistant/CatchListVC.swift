//
//  CatchListByDateVC.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit
import MapKit


// prototype cell definition
class CatchItemCell: UITableViewCell {
    @IBOutlet weak var fishImage: UIImageView!
    @IBOutlet weak var DateOfCatch: UILabel!
    @IBOutlet weak var weather: UILabel!
    @IBOutlet weak var weightOfFish: UILabel!
    @IBOutlet weak var bait: UILabel!
}





// note: This class will be used for all three type of sorting
// three instances will be created under the tab bar controller
class CatchListVC: UIViewController, UITableViewDelegate, UITableViewDataSource,
                        CatchHistoryListener {
    var catchHistory: CatchHistory?
    var sortByCriteria: SortBy?
    let CellID = "CatchItemCell"
    let detailPageID = "detailEditingPage"   // detail editing page vc ID

    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        catchHistory?.delegate.append(self)
        // fix the weird padding on top of the table view
        self.tableView.contentInset = UIEdgeInsetsMake(-60, 0, 0, 0);
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        guard let criteria = self.sortByCriteria else {
            print("sorting criteria not given")
            return
        }
        switch criteria {
        case SortBy.species: self.catchHistory?.itemsSortBySpecies()
        case SortBy.weight: self.catchHistory?.itemsSortByWeight()
        case SortBy.date: self.catchHistory?.itemsSortByDate()
        }
    }
    
    
    
    // set up table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let theDataSource = catchHistory else {
            print("data model not available!")
            return 0
        }
        
        return section == 0 ? theDataSource.numOfItemsIn(type: WaterCategory.freshWater) :
            theDataSource.numOfItemsIn(type: WaterCategory.saltWater)
        
    }
    
    // set up table section title
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return section == 0 ? WaterCategory.freshWater.rawValue : WaterCategory.saltWater.rawValue

    }

    // set section header background color
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor
            = UIColor(hue: 0.5528, saturation: 0.64, brightness: 0.91, alpha: 1.0)
    }
    
    // action on tapping a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let waterType = section == 0 ? WaterCategory.freshWater : WaterCategory.saltWater
        let row = indexPath.row
        
        // go to detail view if is not locked
        guard catchHistory?.itemAtIndexOfType(at: row, type: waterType) != nil else {
            print("record request our of index")
            return
        }
        goToDetailEditingPage(section: waterType, row: row)
    }
    
    
    
    
    
    // UITableViewDelegate
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // set variable heights depending on indexPath
    }
    
    
    // This is a "question" asked by iOS for every cell that appears on-screen
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID, for: indexPath) as? CatchItemCell

        let waterType = (indexPath.section == 0 ? WaterCategory.freshWater : WaterCategory.saltWater)
        
        guard let theRecord = catchHistory?.itemAtIndexOfType(at: indexPath.row, type: waterType) else {
            print("record out of index")
            return UITableViewCell()
        }
        
        if let theImage = theRecord.picture {
            cell?.fishImage.image = theImage
        }
        else {
            cell?.fishImage.image = UIImage(named: "no picture")
        }
        cell?.DateOfCatch.text = getDate(record: theRecord)
        if let weatherSummary = theRecord.weather?.summary {
            cell?.weather.text = weatherSummary
        }
        cell?.bait.text = theRecord.bait
        cell?.weightOfFish.text = String(theRecord.weight)
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ orderDetailTable: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        print("\(type(of: self)): row \(indexPath.row) was tapped")
        return indexPath
    }
    
    
    
    // functions to allow user delete item from tableview
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let section = indexPath.section
            let row = indexPath.row
            let type = (section == 0 ? WaterCategory.freshWater : WaterCategory.saltWater)
            catchHistory?.removeItemAt(at: row, type: type)
        }
    }
    
    
    // get date from record
    func getDate(record: CatchRecord) -> String {
        let date = NSDate(timeIntervalSince1970: TimeInterval(record.timeStamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let timeString = formatter.string(from: date as Date)
        return timeString
    }
    
    
    
    // save change to disk.
    // it was called when user save any changes on any catch record
    private func saveRecords() {
        do {
            print("attempting to save: the records...")
            try Persistence.save(catchHistory!)
        }
        catch let nseInner as NSError {
            print("Failure: \(nseInner.localizedDescription)")
        }
    }

    
    
    // sague to detail editing page for editing certain record
    private func goToDetailEditingPage(section: WaterCategory, row: Int) {
        // create the new View
        guard let detailPage = UIStoryboard.makeVC(detailPageID) as? DetailEditingVC else {
            print("Can't find the right detailEditing page VC!")
            return
        }
        
        
        // pass the record to edit
        let itemToEdit = catchHistory?.itemAtIndexOfType(at: row, type: section)
        detailPage.catchRecord = itemToEdit
        
        
        // set up call back when user tapped save button
        detailPage.saveChangeToItem = { (picture: UIImage, species: Species,
            weight: Double, bait: String, waterType: WaterCategory) -> Void in
            self.catchHistory?.updateItemAt(at: row, type: section, picture: picture, species: species, weight: weight, bait: bait, waterType: waterType)
            print("number of records: \(self.catchHistory!.catchHistory.count)")
            
            // save to disk
            self.saveRecords()
            
        }
        
        // set up call back when user tapped back button
        // do nothing
        detailPage.cancelEditing = { () -> Void in
            return
        }
        
        // push the VC to screen
        navigationController?.pushViewController(detailPage, animated: true)
    }
    

    
    // comfort to delegate protocol
    func catchHistoryChanged() {
        tableView.reloadData()
    }
    
}
