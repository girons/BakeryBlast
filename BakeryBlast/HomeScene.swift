//
//  HomeScene.swift
//  BakeryBlast
//
//  Created by George Irons on 22/06/2017.
//  Copyright © 2017 Girons. All rights reserved.
//


import SpriteKit

class HomeScene: SKScene {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
//        let background = SKSpriteNode(imageNamed: "HomeBackground")
//        background.size = size
//        addChild(background)
    }
}

