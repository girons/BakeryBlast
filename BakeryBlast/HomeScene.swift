//
//  HomeScene.swift
//  BakeryBlast
//
//  Created by George Irons on 22/06/2017.
//  Copyright © 2017 Girons. All rights reserved.
//


import SpriteKit

class HomeScene: SKScene {
    
    // MARK: Properties
    
    // To keep the Sprite Kit node hierarchy neatly organised, HomeScene uses
    // several layers. The base layer is called homeLayer.
    let homeLayer = SKNode()
    let controlsLayer = SKNode()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        homeLayer.isHidden = false
        addChild(homeLayer)
        
        
    }
}

