//
//  Chain.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

class Chain: Hashable, CustomStringConvertible {
    
    // The Cookies that are part of this chain.
    // Using an array here instead of a Set because it is convenient to
    // remember the order of the cookie objects so that you know which cookies
    // are at the ends of the chain. This makes it easier to combine multiple
    // chains into a single one to detect those L- or T-shapes.
    var cookies = [Cookie]()
    
    enum ChainType: CustomStringConvertible {
        case horizontal
        case vertical
        case lShape
        case tShape
        
        // Note: add any other shapes you want to detect to this list.
        // case ChainTypeLShape
        // case ChainTypeTShape
        
        var description: String {
            switch self {
            case .horizontal: return "Horizontal"
            case .vertical: return "Vertical"
            case .lShape: return "lShape"
            case .tShape: return "tShape"
            }
        }
    }
    
    // Whether this chain is horizontal or vertical.
    var chainType: ChainType
    
    // How many points this chain is worth.
    var score = 0
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func add(cookie: Cookie) {
        cookies.append(cookie)
    }
    
    func firstCookie() -> Cookie {
        return cookies[0]
    }
    
    func lastCookie() -> Cookie {
        return cookies[cookies.count - 1]
    }
    
    var length: Int {
        return cookies.count
    }
    
    var description: String {
        return "type:\(chainType) cookies:\(cookies)"
    }
    
    // Performs an exclusive-or on the hash values of all the cookies in the chain.
    // The reduce() function is one of Swift's more advanced functional programming features.
    var hashValue: Int {
        return cookies.reduce (0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.cookies == rhs.cookies
}
