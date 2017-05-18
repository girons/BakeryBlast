//
//  Extensions.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import Foundation

// Using Swit's extension mechanism you can add new methods to existing types.
// Here you have added loadJSONFromBundle(filename:) to load a JSON file from
// the app bundle, into a new dictionary of type Dictionary<String, AnyObject>.
// This means the dictionary's keys are always strings but the associated values
// can be any type of object.
extension Dictionary {
    
    // Loads a JSON file from the app bundle into a new dictionary.
    // Loads the specified file into an NSData object and then converts that to a Dictionary
    // using the NSJSONSerialization API.
    static func loadJSONFromBundle(filename: String) -> Dictionary <String, AnyObject>? {
        var dataOK: Data
        var dictionaryOK: NSDictionary = NSDictionary()
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            let _: NSError?
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions()) as Data!
                dataOK = data!
            }
            catch {
                print("Could not load level file: \(filename), error: \(error)")
                return nil
            }
            do {
                let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
                dictionaryOK = (dictionary as! NSDictionary as? Dictionary <String, AnyObject>)! as NSDictionary
            }
            catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        return dictionaryOK as? Dictionary <String, AnyObject>
    }
    
}
