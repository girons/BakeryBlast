//
//  WelcomeViewController.swift
//  BakeryBlast
//
//  Created by George Irons on 14/07/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import UIKit
import SpriteKit

class WelcomeViewController: UIViewController {
    
    // MARK: Properties
    var scene: WelcomeScene!
    
    
    // MARK: IBOutlets
    @IBOutlet weak var playButton: UIButton!
    
    // MARK: IBActions
    
    
    // MARK: View Controller Functions
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = WelcomeScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        // Present the scene.
        skView.presentScene(scene)
    }
}
