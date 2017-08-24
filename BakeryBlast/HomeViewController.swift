//
//  HomeViewController.swift
//  BakeryBlast
//
//  Created by George Irons on 22/06/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import UIKit
import SpriteKit

class HomeViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: Properties
    
    // The scene displays the map
    var scene: HomeScene!
    
    // MARK: IBOutlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var homeControls: UIImageView!
    
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
        
        // Display the home screen
        setupHome()
        
    }
    
    func setupHome() {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = HomeScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        // Set up and add scrollView to view
        scrollView.frame = self.view.frame
        self.scrollView.isPagingEnabled = true
        self.scrollView.delegate = self
        self.scrollView.contentOffset = CGPoint(x:0, y: 4168)
        
        skView.addSubview(scrollView)
        
        // An array of homeBackground images to add to the view
        let x : [UIImage] = [UIImage(named: "HomeBackground1")!,
                             UIImage(named: "HomeBackground2")!,
                             UIImage(named: "HomeBackground3")!,
                             UIImage(named: "HomeBackground4")!]
        
        // For each UIImage add a view
        for index in 0...x.count-1 {
            let subView = UIScrollView(frame: CGRect(
                x:0,
                y:(self.scrollView.frame.height * CGFloat(index)),
                width:self.scrollView.frame.width,
                height:self.scrollView.frame.height))
            
            // Set the size of the content view
            let contentView = UIImageView(frame: CGRect(x:0, y:0, width:self.view.frame.width, height:self.view.frame.height))
            
            subView.contentSize = CGSize(width:self.view.frame.width, height:contentView.frame.height)
            contentView.image = x[index]
            subView.addSubview(contentView)
            scrollView.addSubview(subView) // Add View
        }
        
        let height = (self.scrollView.frame.size.height) * CGFloat(x.count)
        self.scrollView.contentSize = CGSize(width:self.scrollView.frame.width, height:height)
        
        // Background Colour
        self.view.backgroundColor = UIColor.gray
        
        
        
        // Present the scene.
        skView.presentScene(scene)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

