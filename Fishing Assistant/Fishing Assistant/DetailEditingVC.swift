//
//  DetailEditingVC.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//  some code is copied from lecture example code

import UIKit
import MobileCoreServices

struct Identifiers {
    static let ImagePickerSegue = "Show Image Picker"
}


class DetailEditingVC: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var catchRecord: CatchRecord?               // will be passed in during sague
    var saveChangeToItem: ((UIImage, Species, Double, String, WaterCategory)->Void)?   // call back when user save the changes
    var cancelEditing: (() -> Void)?        // call back when user cancel editing
    
    let mediaTypes = [kUTTypeImage as String]  // only allow still limage
    var sourceType: UIImagePickerControllerSourceType = .camera
    var viewState = DetailEditingViewState()
    var detailViewStateObserver: NSObjectProtocol?
    var theFishImage: UIImage?

    

    @IBOutlet weak var fishImage: UIImageView!
    @IBOutlet weak var SpeciesPicker: UIPickerView!
    
    @IBOutlet weak var weightTextBox: UITextField!
    @IBOutlet weak var baitTextBox: UITextField!
    
    @IBOutlet weak var saltWaterButton: UIButton!
    @IBOutlet weak var freshWaterButton: UIButton!
    
    @IBAction func weightChanged(_ sender: UITextField) {
        viewState.weight = weightTextBox.text!
    }
    
    @IBAction func baitChanged(_ sender: UITextField) {
        viewState.bait = baitTextBox.text!
    }
    
    
    @IBAction func saltWaterButtonPressed(_ sender: UIButton) {
        viewState.waterType = WaterCategory.saltWater
    }
    

    @IBAction func freshWaterButtonPressed(_ sender: UIButton) {
        viewState.waterType = WaterCategory.freshWater
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        if isValidInput() {
            self.saveChangeToItem!(viewState.picture!, viewState.species, Double(viewState.weight)!,  viewState.bait,viewState.waterType!)
            navigationController?.popViewController(animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        // install notification observer
        detailViewStateObserver = Center.addObserver(forName: NSNotification.Name(rawValue: Messages.detailEditingViewStateChanged), object: nil, queue: OperationQueue.main) {
            [weak self] (notification: Notification) in
            if self != nil {
                self?.updateUI()
            }
        }
        
        // initialize the data to display according to the catch record
        self.setupUIData()
        self.updateUI()
        
        // hide default back button and add my own
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel) )
        
        
        setButtonStyle()
        goTOCameraSague()
        
        
        
        self.hideKeyboardWhenTappedAround()
        super.viewDidLoad()
    }
    
    
    
    // called when user tapped back button
    func cancel() {
        self.cancelEditing!()
        navigationController?.popViewController(animated: true)

    }
    
    
    
    // set up UI data according to the passed in catch record
    func setupUIData() {
        guard let record = catchRecord else {
            print("catch record is not available!")
            return
        }
        viewState.waterType = WaterCategory(rawValue: record.waterType)!
        viewState.picture = record.picture ?? UIImage(named: "no picture")
        viewState.species = Species(rawValue: record.species)!
        if record.weight != 0.0 {
            viewState.weight = String(record.weight)
        }
        viewState.bait = record.bait
    }

    
    
    //************************************************
    // functions below are for UIPickerview setup
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Species.count()
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Species.getValueByIndex(index: row).rawValue
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewState.species = Species.getValueByIndex(index: row)
    }

    
    
    // set up button styles
    func setButtonStyle() {
        saltWaterButton.backgroundColor = .clear
        saltWaterButton.layer.cornerRadius = 5
        saltWaterButton.layer.borderWidth = 1
        saltWaterButton.layer.borderColor =  UIColor.black.cgColor
        
        freshWaterButton.backgroundColor = .clear
        freshWaterButton.layer.cornerRadius = 5
        freshWaterButton.layer.borderWidth = 1
        freshWaterButton.layer.borderColor =  UIColor.black.cgColor
    }
    
    

    
    // user input validation
    func isValidInput() -> Bool {
        if viewState.bait == "" {
            alert("Please input the bait you used!")
            return false
        }

        guard let weight  = Double(viewState.weight) else {
            alert("Invalid weight!")
            return false
        }
        
        if weight == 0.0 {
            alert("Invalid weight!")
            return false
        }
        else {
            return true
        }
    }
    
    
    
    // update UI based on view state 
    func updateUI() {
        if viewState.waterType == WaterCategory.freshWater {
            freshWaterButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.cyan), for: .normal)
            saltWaterButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.clear), for: .normal)
        }
        else {
            freshWaterButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.clear), for: .normal)
            saltWaterButton.setBackgroundImage(UIImage.imageWithColor(color: UIColor.cyan), for: .normal)
        }
        
        fishImage.image = viewState.picture
        let row = Species.getIndexByEnum(thevalue: viewState.species)
        SpeciesPicker.selectRow(row, inComponent: 0, animated: false)
        weightTextBox.text =  viewState.weight
        baitTextBox.text = viewState.bait
    }
    

    //************************************************
    // functions below are for taking photos with camera
    // gets called before prepareForSegue, and if false, the prepare/transition is
    // canceled
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier != Identifiers.ImagePickerSegue {
            alert("Unknown segue: \"\(identifier)\"")
            return false
        }
        
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            alert("source type \(sourceType.rawValue) not available")
            return false
        }
        guard let availableTypes = UIImagePickerController.availableMediaTypes(for: sourceType) else {
            preconditionFailure("Could not retrieve media types for \(sourceType.rawValue)")
        }
        // make sure that all the media types we want are in fact available
        for wantedType in mediaTypes {
            if !availableTypes.contains(wantedType) {
                alert("Media type \(wantedType) not available for source type \(sourceType)")
                return false
            }
        }
        return true
    }
    


    // sague to go to camera to ask user to take photos
    func goTOCameraSague() {
        // Might as well use the Storyboard-compatible version
        guard shouldPerformSegue(withIdentifier: Identifiers.ImagePickerSegue, sender: self) else {
            return
        }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType // Camera
        picker.mediaTypes = mediaTypes // Image
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    // delegate "IB"Action for "Use Photo"
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let theThumbnailImage = theImage.resizeImage(targetSize: CGSize.init(width: 120, height: 160))
            theFishImage = theThumbnailImage
            viewState.picture = theThumbnailImage
            UIImageWriteToSavedPhotosAlbum(theImage, self, #selector(DetailEditingVC.verifySaved(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        else {
            alert("No image was picked somehow!")
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    func verifySaved(_ image: UIImage, didFinishSavingWithError: NSError, contextInfo: UnsafeMutableRawPointer) {
        // Output: <NSThread: 0x7feb4250cbe0>{number = 1, name = main} so it is on correct thread already.
        print(Thread.current)
        // alert("Image saved to library at \(Date())")  // disable the alert
    }
    
    
    // delegate for user tapping canel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image picker canceled!")
        dismiss(animated: true, completion: nil)
    }
    
    // show alert
    func alert(_ message: String) {
        let alert = UIAlertController(title: "Invalid input", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    

}
