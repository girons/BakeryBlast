//
//  Swap.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) ||
        (lhs.cookieB == rhs.cookieA && lhs.cookieA == rhs.cookieB)
}

// The reason you can make Swap into a struct is that this object does not have an
// "identity". A Swap that links to cookieX and cookieY is identical to another Swap
// instance that links to cookieX and cookieY, even those these two instances each
// take up their own space in memory. So these two Swap instances are interchangeable,
// which is why they dont'have an identity.

// Object to describe an attempted swap.
struct Swap: CustomStringConvertible, Hashable {
    let cookieA: Cookie
    let cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
    
    var description: String {
        return "swap \(cookieA) with \(cookieB)"
    }
    
    // Combines the hash values of the two cookies with the exclusive-or operator.
    // That's a common trick to make hash values.
    var hashValue: Int {
        return cookieA.hashValue ^ cookieB.hashValue
    }
}
