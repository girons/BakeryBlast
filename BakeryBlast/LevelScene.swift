//
//  LevelScene.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import SpriteKit

class LevelScene: SKScene {
    
    // MARK: Properties
    
    // This is marked as ! because it will not initially have a value, but pretty
    // soon after the LevelScene is created it will be given a Level object, and
    // from then on it will always have one (it will never be nil again).
    var level: Level!
    
    // Each sqaure of the 2D grid measures 32 by 36 points.
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    // To keep the Sprite Kit node hierarchy neatly organised, LevelScene uses
    // several layers. The base layer is called gameLayer.
    // cropLayer is a special kind of node called a SKCropNode, and a mask layer.
    // A crop node only draws its children where the mask contains pixels. This
    // lets you draw the cookies only where there is a tile, but never on the
    // background.
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    // The column and row numbers of the cookie that the player first touched
    // when he started his swipe movement. These are marked ? because they may
    // become nil (meaning no swipe is in progress).
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    
    // The scene handles touches. If it recognises that the user makes a swipe,
    // it will call this swipe handler. This is how it communicates back to the
    // ViewController that a swap needs to take place. You could also use a
    // delegate for this.
    // The type of this variable is ((Swap) -> ())?. Because of the -> you can tell
    // this is a closure or function.This closure or function takes a Swap object as
    // its parameter and does not return anything. The ? indicates that swipeHandler
    // is allowed to be nil (it is an optional).
    var swipeHandler: ((Swap) -> ())?
    
    // Sprite that is drawn on top of the cookie that the player is trying to swap.
    var selectionSprite = SKSpriteNode()
    
    // Pre-load sounds
    
    // Rather than recreate an SKAction every time you need to play a sound, you'll load all the sounds
    // just once and keep re-using them.
//    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
//    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
//    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
//    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
//    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    
    // MARK: Init
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Put an image on the background. Because the scene's anchorPoint is
        // (0.5, 0.5), the background image will always be centered on the screen.
        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        addChild(background)
        
        // Add a new node that is the container for all other layers on the playing
        // field. This gameLayer is also centered in the screen.
        gameLayer.isHidden = true
        addChild(gameLayer)
        
        // Because column 0, row 0 is in the bottom-left corner of the 2D grip, you
        // want the positions of the sprites to be relative to the cookieLays's
        // bottom-left corner, as well. That's why we move the layer down and to the
        // left by half the height and width of the grid.
        let layerPosition = CGPoint(
            x: -TileWidth * CGFloat(NumColumns) / 2,
            y: -TileHeight * CGFloat(NumRows) / 2)
        
        // The tiles layer represents the shape of the level. It contains a sprite
        // node for each square that is filled in.
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        // We use a crop layer to prevent cookies from being drawn across gaps
        // in the level design.
        gameLayer.addChild(cropLayer)
        
        // The mask layer determines which part of the cookiesLayer is visible.
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        // This layer holds the Cookie sprites. The positions of these sprites
        // are relative to the cookiesLayer's bottom-left corner.
        cookiesLayer.position = layerPosition
        cropLayer.addChild(cookiesLayer)
        
        // nil means that there properties have invalid values i.e. they dont't
        // yet point at any of the cookies.
        swipeFromColumn = nil
        swipeFromRow = nil
        
        // Pre-load the label font to prevent delays during game play.
        // When using SKLabelNode, Sprite Kit needs to load the font and convert it
        // to a texture. That only happens once, but it does create a small delay,
        // so it's smart to pre-load this font before the game starts in earnest.
        let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    
    
    // MARK: Level Setup
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                // If there is a tile at this position, then create a new tile
                // sprite and add it to the mask layer.
                if level.tileAt(column: column, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    tileNode.position = pointFor(column: column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        // The tile pattern is drawns *in between* the level tiles. That's why
        // there is an extra column and row of them.
        // This draws a pattern of border pieces in between the level tiles.
        for row in 0...NumRows {
            for column in 0...NumColumns {
                
                let topLeft     = (column > 0) && (row < NumRows)
                    && level.tileAt(column: column - 1, row: row) != nil
                let bottomLeft  = (column > 0) && (row > 0)
                    && level.tileAt(column: column - 1, row: row - 1) != nil
                let topRight    = (column < NumColumns) && (row < NumRows)
                    && level.tileAt(column: column, row: row) != nil
                let bottomRight = (column < NumColumns) && (row > 0)
                    && level.tileAt(column: column, row: row - 1) != nil
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by combining these four values.
                let value =
                        Int(topLeft.hashValue) |
                        Int(topRight.hashValue) << 1 |
                        Int(bottomLeft.hashValue) << 2 |
                        Int(bottomRight.hashValue) << 3
                
                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    tileNode.size = CGSize(width: TileWidth, height: TileHeight)
                    var point = pointFor(column: column, row: row)
                    point.x -= TileWidth/2
                    point.y -= TileHeight/2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func addSprites(for cookies: Set<Cookie>) {
        for cookie in cookies {
            // Create a new sprite for the cookie and add it to the cookiesLayer.
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.size = CGSize(width: TileWidth, height: TileHeight)
            sprite.position = pointFor(column: cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            
            // Give each cookie sprite a small, random delay. Then fade them in.
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
               SKAction.sequence([
                SKAction.wait(forDuration: 0.25, withRange: 0.5),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 1.0),
                    SKAction.scale(to: 1.0, duration: 0.25)
                    ])
                ]))
        }
    }
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    
    
    // MARK: Point conversion
    
    // Converts a column,row pair into a CGPoint that is relative to the cookieLayer.
    // This point represents the center of the cookies SKSpriteNode.
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column)*TileWidth + TileWidth/2,
            y: CGFloat(row)*TileHeight + TileHeight/2)
    }
    
    // Converts a point relative to the cookieLayer into column and row numbers.
    func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        // Is this a valid location within the cookies layer? If yes,
        // calculate the corresponding row and column numbers.
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
            // Returns a tuple with three values: 1) the boolean that indicates success
            // of failure; 2) the column number; and 3) the row number. If the point
            // falls outside the grid, this method returns false for success.
            return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0) // invalid location
        }
    }
    
    
    // MARK: Cookie Swapping
    
    // We get here after the user performs a swipe. This sets in motion a whole
    // chain of events: 1) swap the cookies, 2) remove the matching lines, 3)
    // drop new cookies into the screen, 4) check if they create new matches,
    // and so on.
    func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
        // Calculate the column and row numbers of the cookie to swap with.
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        // Going outside the bounds of the array? This happens when the user swipes
        // over the edge of the grid. We should ignore such swipes.
        guard toColumn >= 0 && toColumn < NumColumns else { return }
        guard toRow >= 0 && toRow < NumRows else { return }
        
        // Can't swap if there is no cookie to swap with. This happens when the user
        // swipes into a gap where there is no tile.
        if let toCookie = level.cookieAt(column: toColumn, row: toRow),
            let fromCookie = level.cookieAt(column: swipeFromColumn!, row: swipeFromRow!),
            let handler = swipeHandler {
                // Communicate this swap request back to the ViewController.
                // Creates a new Swap object, fills in the two cookies to be swapped and
                // then calls the swipe handler to take care of the rest.
                let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                handler(swap)
        }
    }
    
    // This method gets the name of the highlighted sprite image from the Cookie object and
    // puts the corresponding texture on the selection sprite.
    func showSelectionIndicatorFor(cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: TileWidth, height: TileHeight)
            
            // Simply setting the texture on the sprite doesn't give it the correct size
            // but using an SKAction does.
            selectionSprite.run(SKAction.setTexture(texture))
            
            // Add the selection sprite as a child of the cookie sprite so that it
            // moves along with the cookie sprite in the swap animation.
            sprite.addChild(selectionSprite)
            // Make the selection sprite visible by settings its alpha to 1.
            selectionSprite.alpha = 1.0
        }
    }
    
    // This method removes the selection sprite by fading it out.
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }
    
    
    // MARK: Animations
    
    // Move cookieA to the position of cookieB and vice versa.
    // The cookie that was the origin of the swipe is in cookieA and the animation looks 
    // best if that one appears on top, so this method adjusts the relative zPosition of
    // the two cookie sprites to make that happen.
    // After the animation completes, the action on cookieA calls a completion block so
    // the caller can continue doing whatever it needs to do. That's a common pattern for
    // this game: The game waits until an animation is complete and then it resumes.
    // () -> () is simply shorthand for a closure that returns void and takes no parameters.
    func animate(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        
        // run(swapSound)
    }
    
    // This method slides the cookies to their new positions and then immediately flips them back.
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        
        // run(invalidSwapSound)
    }
    
    func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> ()) {
        // Loops through all the chains and all the cookies each chain,
        // and then triggers the animations.
        for chain in chains {
            animateScore(for: chain)
            for cookie in chain.cookies {
                
                // It may happen that the same Cookie object is part of two chains
                // (L-shape or T-shape match). In that case, its sprite should only be
                // removed once.
                if let sprite = cookie.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                   withKey: "removing")
                    }
                }
            }
        }
        // run(matchSound)
        
        // The WaitForDuration() action ensures that the rest of the game will only continue
        // after the animations finish.
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    func animateFallingCookies(columns: [[Cookie]], completion: @escaping () -> ()) {
        
        // As with the other animation methods, you should only call the completion block
        // after all the animations are finished. Because the number of falling cookies may
        // vary, you can't hardcode this total duration but instead have to compute it.
        var longestDuration: TimeInterval = 0
        for array in columns {
            for (idx, cookie) in array.enumerated() {
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                
                // The further away from the hole you are, the bigger the delay
                // on the animation.
                // This calculation works because fillHoles() guarantees that lower cookies
                // are first in the array.
                let delay = 0.05 + 0.15*TimeInterval(idx)
                
                let sprite = cookie.sprite!    // sprite always exists at this point
                
                // Calculate duration based on how far cookie has to fall (0.1 seconds
                // per tile).
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight)
                    * 0.1)
                
                // Calculate which animation is the longest. This is the time that game has
                // to wait before it may continue.
                longestDuration = max(longestDuration, duration + delay)

                // Perform the animation, which consists of a delay, a movement and a sound effect.
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([moveAction])]))
                        // SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        
        // Wait until all the cookies have fallen down before we continue.
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewCookies(_ columns: [[Cookie]], completion: @escaping () -> ()) {
        // We don't want to continue with the game until all the animations are
        // complete, so we calculate how long the longest animation lasts, and
        // wait that amount before we trigger the completion block.
        var longestDuration: TimeInterval = 0.7
        
        for array in columns {
            
            // The new sprite should start out just above the first tile in this column.
            // An easy way to find this tile is to look at the row of the first cookie
            // in the array, which is always the top-most one for this column.
            let startRow = array[0].row + 1
            
            for (idx, cookie) in array.enumerated() {
                
                // Create a new sprite for the cookie.
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.size = CGSize(width: TileWidth, height: TileHeight)
                sprite.position = pointFor(column: cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                
                // Give each cookie that's higher up a longer delay, so they appear to
                // fall after one another.
                let delay = 0.1 + 0.2 * TimeInterval(array.count - idx - 1)
                
                // Calculate duration based on how far the cookie has to fall.
                let duration = TimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                // Animate the sprite falling down. Also fade it in to make the sprite
                // appear less abruptly.
                let newPosition = pointFor(column: cookie.column, row: cookie.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction])
//                        , addCookieSound])
                        ]))
            }
        }
        
        // Wait until the animations are done before we continue.
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    // This method creates a new SKLabelNode with the score and places it in the center
    // of the chain. The numbers will float up a few pixels before disappearing.
    func animateScore(for chain: Chain) {
        // Figure out what the midpoint of the chain is.
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
        // Add a label for the score that slowly floats up.
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
    
        // Detects the type of the cookies in the chain and changes
        // the scoreLabel text colour to reflect this.
        let cookieType = chain.firstCookie().cookieType.spriteName
        switch cookieType {
        case "Croissant":
            scoreLabel.fontColor = UIColor.orange
        case "Cupcake":
            scoreLabel.fontColor = UIColor.red
        case "Danish":
            scoreLabel.fontColor = UIColor.blue
        case "Donut":
            scoreLabel.fontColor = UIColor.purple
        case "Macaroon":
            scoreLabel.fontColor = UIColor.green
        case "SugarCookie":
            scoreLabel.fontColor = UIColor.yellow
        default:
            scoreLabel.fontColor = UIColor.white
        }
        
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 15), duration: 0.6)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    // This mehtod animates the entire gameLayer out of the way.
    func animateGameOver(_ completion: @escaping () -> ()) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    // This method slides the gameLayer back in from the top of the screen.
    func animateBeginGame(_ completion: @escaping () -> ()) {
        gameLayer.isHidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
    
    
    // MARK: Cookie Swipe Handlers
    
    // This method needs to be marked *override* because the base class SKScene already
    // contains a version of touchesBegan. This is how you tell Swift that you want it
    // to use your own version.
    // The game calls touchesBegan() whenever the user puts their finger on the screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // Convert the touch location to a point relative to the cookiesLayer.
        let location = touch.location(in: cookiesLayer)
        
        // If the touch is inside a square, then this might be the start of a
        // swipe motion.
        let (success, column, row) = convertPoint(location)
        if success {
            // The touch must be on a cookie, not on an empty tile.
            if let cookie = level.cookieAt(column: column, row: row) {
                // Remember in which column and row the swipe started, so we can compare
                // them later to find the direction of the swipe. This is also the first
                // cookie that will be swapped.
                swipeFromColumn = column
                swipeFromRow = row
                showSelectionIndicatorFor(cookie: cookie)
            }
        }
    }
    
    // touchesMoved() contains the logic for detecting the swipe direction.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If swipeFromColumn is nil then either the swipe began outside
        // the valid area or the game has already swapped the cookies and we need
        // to ignore the rest of the motion.
        guard swipeFromColumn != nil else { return }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: cookiesLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            // Figure out in which direction the player swiped by comparing the new 
            // column and row numbers to the previous ones. Diagonal swipes
            // are not allowed.
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            
            // Only try swapping when the user swiped into a new square.
            if horzDelta != 0 || vertDelta != 0 {
                trySwap(horizontal: horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                
                // Ignore the rest of this swipe motion from now on.
                swipeFromColumn = nil
            }
        }
    }
    
    // This method is called when the user lifts their finger from the screen.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Remove the selection indicator with a fade-out. We only need to do this
        // when the player didn't actually swipe.
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        
        // If the gesture ended, regardless of whether it was a valid swipe or not,
        // reset the starting column and row numbers.
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    // This method is called when iOS decides that it must interrupt the touch (for
    // example, because of an incoming phone call).
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
