//
//  Persistence.swift
//
//  Created by Daniel Bromberg on 7/20/15.
//  Copyright (c) 2015 S65. All rights reserved.
//


// this code is from lecture example. I did not change anything
import Foundation


class Persistence {
    // All running on UI thread
    static let ModelFileName = "AppModel.serialized"
    static let FileMgr = FileManager.default
    
    // Resources on disk: URLs: "file:///path/to/file"
    static func getStorageURL() throws -> URL {
        // Important: searchpath API
        let dirPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if dirPaths.count == 0 {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "No paths found"])
        }
        // Application support directory does not automatically get created
        // First time run of App, have to create it
        let urlPath = URL(fileURLWithPath: dirPaths[0])
        if !FileMgr.fileExists(atPath: dirPaths[0]) {
            try mkdir(urlPath)
        }
        
        // Create a filename to store things
        // Valid characters: A-Za-z0-9_. (also valid are: + - , but avoid)
        return urlPath.appendingPathComponent(ModelFileName)
    }
    
    
    // think of it as black box to create a directory on iOS filesystem
    static func mkdir(_ newDirURL: URL) throws {
        try FileManager.default.createDirectory(at: newDirURL, withIntermediateDirectories: false, attributes: nil)
    }
    
    
    // Model must inherit from NSObject -- and be a reference type -- structs don't
    // Rather than using full hierarchical capabilities of NSKeyedArchiver,
    // just one object, so it's the "root" object of the file
    static func save(_ model: NSObject) throws {
        let saveURL = try Persistence.getStorageURL()
        print("saveURL: \(saveURL)")
        // This is a recursive process that will push archiving to the children if set up that way
        let success = NSKeyedArchiver.archiveRootObject(model, toFile: saveURL.path)
        if !success {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to archive"])
        }
        print("saved model success: \(success) at \(Date()) to path: \(saveURL)")
    }
    
    
    static func restore() throws -> NSObject {
        let saveURL = try Persistence.getStorageURL()
        guard let rawData = try? Data(contentsOf: URL(fileURLWithPath: saveURL.path)) else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve unarchival data"])
        }
        // rawData is the bytes on disk to transform into the object previously saved
        let unarchiver = NSKeyedUnarchiver(forReadingWith: rawData)
        // Important: unarchiving
        guard let model = unarchiver.decodeObject(forKey: "root") as? NSObject else {
            throw NSError(domain: "File I/O", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find root object"])
        }
        print("restored model successfully at \(Date()): \(type(of: model))")
        return model
     }
}
