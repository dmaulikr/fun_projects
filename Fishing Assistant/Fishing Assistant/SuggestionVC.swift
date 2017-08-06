//
//  SuggestionPageVC.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit

class SuggestionVC: UIViewController {
    var bestForFreshWater: BestCondition?
    var bestForSaltWater: BestCondition?
    
 
    @IBOutlet weak var saltWaterBestTemp: UILabel!
    
    @IBOutlet weak var saltWaterBestTide: UILabel!
    
    @IBOutlet weak var saltWaterBestWeather: UILabel!
    
    @IBOutlet weak var saltWaterMostCatch: UILabel!
    
    
    @IBOutlet weak var freshWaterBestTemp: UILabel!
    
    @IBOutlet weak var freshWaterBestTime: UILabel!
    
    @IBOutlet weak var freshWaterBestWeather: UILabel!
    
    @IBOutlet weak var freshWaterMostCatch: UILabel!
    
    
    @IBAction func OKButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    // update UI
    func updateUI() {
        saltWaterBestTemp.text = bestForSaltWater?.temp
        saltWaterBestTide.text = bestForSaltWater?.tide
        saltWaterMostCatch.text = bestForSaltWater?.mostCatch
        saltWaterBestWeather.text = bestForSaltWater?.weather
        
        freshWaterBestTemp.text = bestForFreshWater?.temp
        freshWaterBestTime.text = bestForFreshWater?.time
        freshWaterBestWeather.text = bestForFreshWater?.weather
        freshWaterMostCatch.text = bestForFreshWater?.mostCatch
    }
    
    
    
    
}
