//
//  Misc.swift
//  Fishing Assistant
//
//  Created by litao chen on 7/29/17.
//  Copyright © 2017 litao chen. All rights reserved.
//

import Foundation
import UIKit

// this file contains the general supporting enums settings and extensions
let Center = NotificationCenter.default

struct Messages {
    static let detailEditingViewStateChanged = "Detail editing view state changed"
    static let dataFromNetworkArrvied = "Data from network arrived"
}




// extension to resize image
// this code was copied from:
//https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

// hide keyboard when editing is done
// code is from:
// https://stackoverflow.com/questions/24126678/close-ios-keyboard-by-touching-anywhere-using-swift
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}


// new method to UIStoryboard
// from lecture example code
extension UIStoryboard {
    // Rather than return an Optional, this raises an exception which crashes the program if the ID is invalid.
    static func makeVC(_ viewControllerID: String, from: String = "Main") -> UIViewController {
        let board = UIStoryboard(name: from, bundle: nil)
        return board.instantiateViewController(withIdentifier: viewControllerID)
    }
}

// set background color through drawing
// for button background color rendering upon loading
// from professor's code on piazza and the link:
// https://stackoverflow.com/questions/35931156/how-to-set-uibutton-background-color-by-state
extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let tinyRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(tinyRect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(tinyRect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}







