//
//  GameViewController.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    
    // MARK: Properties
    
    // The scene draws the tiles and cookie sprites, and handles swipes.
    var scene: GameScene!
    
    // The level contains the tiles, the cookies, and most of the gameplay logic.
    // Needs to be ! because it's not set in init() but in viewDidLoad().
    var level: Level!
    var currentLevelNum = 1
    
    var movesLeft = 0
    var score = 0
    
    var tapGestureRecognizer: UITapGestureRecognizer!

    // What you see here is a common pattern for declaring a variable and initializing it in the same statement.
    // The initialization code sits in a closure. It loads the background music MP3 and sets it to loop forever.
    // Because the variable is marked lazy, the code from the closure won't run until backgroundMusic is
    // first accessed.
    
//    lazy var backgroundMusic: AVAudioPlayer? = {
//        guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3") else {
//            return nil
//        }
//        do {
//            let player = try AVAudioPlayer(contentsOf: url)
//            player.numberOfLoops = -1
//            return player 
//        } catch {
//            return nil
//        }
//    }()
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverPanel: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    
    
    // MARK: IBActions
    
    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        
        // Pressing the shuffle button costs a move.
        decrementMoves()
    }
    
    
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
        
        // Setup view with level 1
        setupLevel(currentLevelNum)
        
        // Start the background music.
//        backgroundMusic?.play()
    }
    
    
    // MARK: Game functions
    
    func setupLevel(_ levelNum: Int) {
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        // Setup the level.
        level = Level(filename: "Level_\(levelNum)")
        scene.level = level
        
        scene.addTiles()
        
        // Assigns the handleSwipe() function to GameScene's
        // swipeHandler property. Now whenever GameScene calls
        // swipeHandler(swap), it actually calls a function in
        // GameViewController. This works because in Swift you
        // can user functions and closures interchangeably.
        scene.swipeHandler = handleSwipe
        
        gameOverPanel.isHidden = true
        shuffleButton.isHidden = true
        
        // Present the scene.
        skView.presentScene(scene)
        
        // Start the game.
        beginGame()
    }
    
    func beginGame() {
        // Resets everything to starting values.
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        
        level.resetComboMultiplier()
        
        scene.animateBeginGame() {
            self.shuffleButton.isHidden = false
        }
        
        shuffle()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
        
        // Fill up the level with new cookies, and create sprites for them.
        let newCookies = level.shuffle()
        scene.addSprites(for: newCookies)
    }
    
    // This is the swipe handler. MyScene invokes this function whenever it
    // detects that the player performs a swipe.
    func handleSwipe(_ swap: Swap) {
        // While cookies are being matched and new cookies fall down to fill up
        // the holes, we don't want the player to tap on anything.
        view.isUserInteractionEnabled = false
        
        // Only perform the swap if it's in the list of sanctioned swaps.
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            
            // Recall that in Swift a closure and a function are really the same
            // thing, so instead of passing a closure block to animate(swap:completion:),
            // you can also give it the name of a function.
            scene.animate(swap, completion: handleMatches)
            self.view.isUserInteractionEnabled = true
        } else {
            // Animate an invalid swap.
            scene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.isUserInteractionEnabled = true
        
        decrementMoves()
    }
    
    // This is the main loop that removes any matching cookies and fills up the
    // holes with new cookies. While this happens, the user cannot interact with
    // the app.
    func handleMatches() {
        // Detect if there are any matches left.
        let chains = level.removeMatches()
        
        // If there are no more matches, then the player gets to move again.
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        
        // First, remove any matches...
        scene.animateMatchedCookies(for: chains) {
            
            // Loops through the chains, adds their scores to the player's
            // total and then updates the labels.
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            
            // ...then shift down any cookies that have a hole below them...
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns: columns) {
                
                // ...and finally, add new cookies at the top.
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    
                    // Keep repeating this cycle until there are no more matches.
                    self.handleMatches()
                }
            }
        }
    }
    
    // This method is called after every turn to update the text
    // inside the labels.
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    func decrementMoves() {
        movesLeft -= 1
        updateLabels()
        
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            // Increment the current level, go back to level 1 if the current level
            // is the last one.
            currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
    
    // This method un-hides the image view, disables touches on the scene to prevent the player
    // from swiping and adds a tap gesture recognizer that will restart the game.
    func showGameOver() {
        gameOverPanel.isHidden = false
        shuffleButton.isHidden = true
        scene.isUserInteractionEnabled = false
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    // This method hides the game over panel and restarts the game.
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.isHidden = true
        scene.isUserInteractionEnabled = true
        
        setupLevel(currentLevelNum)
    }
    
}
