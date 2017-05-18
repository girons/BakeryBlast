//
//  Cookie.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import SpriteKit

// MARK: - CookieType

enum CookieType: Int, CustomStringConvertible {
    case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
    
    // The spriteName property returns the filename of the corresponding sprite image
    // in the texture atlas.
    var spriteName: String {
        let spriteNames = [
          "Croissant",
          "Cupcake",
          "Danish",
          "Donut",
          "Macaroon",
          "SugarCookie"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    var description: String {
        return spriteName
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
}


// MARK: - Cookie

// Whenever you add the Hashable protocol to an object, you also need to supply the ==
// comparison operator for comparing two objects of the same type.
func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

// Cookie are used in a Set and the objects that you put into the set must conform to
// the Hashable protocol. This is a requirement from Swift.
class Cookie: CustomStringConvertible, Hashable {
    // The column and row properties let Cookie keep track of its position in the 2D grid.
    var column: Int
    var row: Int
    let cookieType: CookieType
    // The sprite property is ? because the cookie object may not always have its sprite set.
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    
    var description: String {
        return "type:\(cookieType) square:(\(column),\(row))"
    }
    
    // The Hashable protcol requires that you add a hashValue property to the object. This should
    // return an Int value that is as unique as possible.
    var hashValue: Int {
        return row*10 + column
    }

}
