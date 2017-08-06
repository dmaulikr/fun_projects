//
//  CatchListTabBarVC.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit

class CatchListTabBarVC: UITabBarController, UITabBarControllerDelegate {
    var catchHistory: CatchHistory?
    
    
    override func viewDidLoad() {
        // create the three VCs
        let catchListByDateVC = UIStoryboard.makeVC("catchListPage") as! CatchListVC
        let catchListByWeightVC = UIStoryboard.makeVC("catchListPage") as! CatchListVC
        let catchListBySpeciesVC = UIStoryboard.makeVC("catchListPage") as! CatchListVC
 
        
        // pass the data into each VC
        catchListByDateVC.catchHistory = self.catchHistory
        catchListByDateVC.sortByCriteria = SortBy.date
        catchListByWeightVC.catchHistory = self.catchHistory
        catchListByWeightVC.sortByCriteria = SortBy.weight
        catchListBySpeciesVC.catchHistory = self.catchHistory
        catchListBySpeciesVC.sortByCriteria = SortBy.species
        
    
        // attach the VCs to the tabBar controller
         self.setViewControllers([catchListByDateVC, catchListByWeightVC, catchListBySpeciesVC], animated: true)
 
        // set up tab bar image and title
        self.tabBar.items?[0].image = UIImage(named: "byDate")
        self.tabBar.items?[0].title = "By Date"
        
        self.tabBar.items?[1].image = UIImage(named: "byWeight")
        self.tabBar.items?[1].title = "By Weight"
        
        self.tabBar.items?[2].image = UIImage(named: "bySpecies")
        self.tabBar.items?[2].title = "By Species"
        

        super.viewDidLoad()
    }

    
}
