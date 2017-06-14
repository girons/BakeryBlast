//
//  Level.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

import Foundation

// Declare two constants for the dimensions of the level.
let NumColumns = 9
let NumRows = 9
let NumLevels = 4 // Excluding Level_0.json

class Level {
    
    // MARK: Properties
    
    // The 2D array that keeps track of where the Cookies are.
    fileprivate var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    
    // The 2D array that contains the layout of the level.
    // Very similar to the cookies array, except now you make it an Array2D
    // of Tile objects.
    // Wherever tiles[a, b] is nil, the grid is empty and cannot contain a cookie.
    fileprivate var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    
    // The 2D array that contains the cookies to place at the beginning of the level, in
    // the instance that we do not want the initial cookies displayed to be random.
    fileprivate var beginLevelCookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    
    // The list of swipes that result in a valip swap. Used to determine whether
    // the player can make a certain swap, whether the board needs to be shuffled,
    // and to generate hints.
    // Using a Set here instead of an Array because the order of the elements in this
    // collection isn't important.
    fileprivate var possibleSwaps = Set<Swap>()
    
    var targetScore = 0
    var maximumMoves = 0
    
    // The second chain gets twice its regular score, the third chain three times,
    // and so on. This multiplier is reset for every next turn.
    fileprivate var comboMultiplier = 0
    
    
    // MARK: Initialization
    
    // Create a level by loading it from a file.
    init(filename: String) {
        // Load the named file into a Dictionary using the loadJSONFromBundle(filename:) helper function.
        // Not that this function may return nil -- it returns an optional -- and here you use a *guard*
        // to handle this situation.
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        // The dictionary contains an array named "tiles". This array contains
        // one element for each row of the level. Each of those row elements in
        // turn is also an array describing the columns in that row. If a column
        // is 1, it means there is a tile at that location, 0 means there is not.
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        
        // Loop through the rows...
        for (row, rowArray) in tilesArray.enumerated() {
            // Note: In Sprite Kit (0,0) is at the bottom of the screen,
            // so we need to read this file upside down.
            let tileRow = NumRows - row - 1
            
            // Loop through the columns in the current row
            for (column, value) in rowArray.enumerated() {
                // If the value is 1, create a tile object and place into
                // the tiles array.
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        
        // By this point you've parsed the JSON into a dictionary, so you grab
        // the two values and store them.
        targetScore = dictionary["targetScore"] as! Int
        maximumMoves = dictionary["moves"] as! Int
        
        // The dictionary may contain an array named "beginLevelCookies". This array contains
        // one element for each row of the level. Each of those row elements in turn is also an
        // array describing the columns in that row. If a column is 1 = Croissant, 2 = Cupcake,
        // 3 = Danish, 4 = Donut, 5 = Macaroon, 6 = SugarCookie, 0 = Empty.
        guard let beginLevelCookiesArray = dictionary["beginLevelCookies"] as? [[Int]] else { return }
        for (row, rowArray) in beginLevelCookiesArray.enumerated() {
            let cookieRow = NumRows - row - 1
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(1))!)
                }
                else if value == 2 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(2))!)
                }
                else if value == 3 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(3))!)
                }
                else if value == 4 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(4))!)
                }
                else if value == 5 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(5))!)
                }
                else if value == 6 {
                    beginLevelCookies[column, cookieRow] = Cookie.init(column: column, row: cookieRow, cookieType: CookieType(rawValue: Int(6))!)
                }
            }
        }
    }
    
    // MARK: Level Setup
    
    // Fills up the level with new Cookie objects. The level is guaranteed free
    // from matches at this point.
    // You call this method at the beginning of the game.
    // Returns a set containing all the new Cookie objects (Set<Cookie>).
    func beginGameShuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        // Check to see whether the level file has a pre-defined begin level cookies
        // state. If the array is empty, then you create random cookies to fill the grid.
        // Else we load the initial state from the level.json file.
        if beginLevelCookiesIsNil(beginLevelCookies) {
            repeat {
                // Removes the old cookies and fills up the level with all new ones.
                set = createInitialCookies()
            
                // At the start of each turn we need to detect which cookies that player can
                // actually swap. If the player tries to swap two cookies that are not in
                // this set, then the game does not accept this as a valid move.
                // This also tells you whether no more swaps are possible and the game needs
                // to automatically reshuffle.
                detectPossibleSwaps()
//              print("possible swaps: \(possibleSwaps)")
            // If there are no possible moves,then keep trying again until there are.
            } while possibleSwaps.count == 0
        
            return set
        }
        else {
            set = loadInitialCookiesFromFile()
            detectPossibleSwaps()
            return set
        }
    }
    
    // Fills up the level with new Cookie objects. The level is guaranteed free
    // from matches at this point.
    // You call this method whenever the player taps the Shuffle button.
    // Returns a set containing all the new Cookie objects (Set<Cookie>).
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        
        repeat {
            // Removes the old cookies and fills up the level with all new ones.
            set = createInitialCookies()
            // At the start of each turn we need to detect which cookies that player can
            // actually swap. If the player tries to swap two cookies that are not in
            // this set, then the game does not accept this as a valid move.
            // This also tells you whether no more swaps are possible and the game needs
            // to automatically reshuffle.
            detectPossibleSwaps()
        // If there are no possible move, then keep trying again until there are.
        } while possibleSwaps.count == 0
        
        return set
    }
    
    
    // Returns true is the beginLevelCookies array is nil or empty. Returns
    // false otherwise.
    fileprivate func beginLevelCookiesIsNil(_: Array2D<Cookie>) -> Bool {
        var result: Bool
        result = false
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if beginLevelCookies[column, row] == nil {
                    result = true
                }
                else {
                    result = false
                    return result
                }
            }
        }
        return result
    }

    // Returns a set containing the level defined initial Cookie objects
    // (Set<Cookie>).
    fileprivate func loadInitialCookiesFromFile() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        // Loop through the rows and columsn of the 2D array. Note that column 0,
        // row 0 is in the bottom-left corner of the array.
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                // Only add to the set if there is a cookie on this tile.
                if beginLevelCookies[column, row] != nil {
                    let cookie = beginLevelCookies[column, row]!
                    set.insert(cookie)
                    cookies[column, row] = cookie
                }
            }
        }
        return set
    }
    
    // Returns a set containing all the new Cookie objects (Set<Cookie>).
    fileprivate func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        // Loop through the rows and columns of the 2D array. Note that column 0,
        // row 0 is in the bottom-left corner of the array.
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                // Only make a new cookie if there is a tile at this spot.
                if tiles[column, row] != nil {
                    
                    // Pick the cookie type at random, and make sure that this never
                    // creates a chain of 3 or more. We want there to be 0 matches in
                    // the initial state.
                    var cookieType: CookieType
                    
                    /*
                     repeat {
                        generate a new random cookie type
                     }
                     while there are already two cookies of this type to the left
                     or there are already two cookies of this type below
                    */
                    repeat {
                        cookieType = CookieType.random()
                    } while
                        (column >= 2 &&
                          cookies[column - 1, row]?.cookieType == cookieType &&
                          cookies[column - 2, row]?.cookieType == cookieType) ||
                        (row >= 2 &&
                          cookies[column, row - 1]?.cookieType == cookieType &&
                          cookies[column, row - 2]?.cookieType == cookieType)
                    
                    // Create a new cookie and add it to the 2D array.
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    
                    // Also add the cookie to the set so we can tell our caller about it.
                    set.insert(cookie)
                }
            }
        }
        return set
    }
    
    
    // MARK: Query the level
    
    // Determines whether there's a tile at the specified column and row.
    func tileAt(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    // Returns the cookie at the specified column and row, or nil when there is none.
    // Using cookieAt(column: 3, row: 6) you can ask the Level for the cookie at
    // column 3, row 6. Behind the scenes this asks the Array2D for the cookie and
    // then returns it.
    func cookieAt(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
    }
    
    // Determines whether the suggested swap is a valid one, i.e. it results in at
    // least one new chain of 3 or more cookies of the same type.
    // Looks to see if the set of possibel swaps contains the specified Swap object.
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    fileprivate func hasChainAt(column: Int, row: Int) -> Bool {
        // Here we do ! because we know there is a cookie here
        let cookieType = cookies[column, row]!.cookieType
        
        // Horizontal chain check
        var horzLength = 1
        
        // Left
        var i = column - 1
        // Here we do ? because there may be no cookie there; if there isn't then
        // the loop will terminate because it is != cookieType. (So there is no
        // need to check whether cookies[i, row] != nil.)
        while i >= 0 && cookies[i, row]?.cookieType == cookieType {
            i -= 1
            horzLength += 1
        }
        
        // Right
        i = column + 1
        while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
            i += 1
            horzLength += 1
        }
        if horzLength >= 3 { return true }
        
        // Vertical chain check
        var vertLength =  1
        
        // Down
        i = row - 1
        while i >= 0 && cookies[column, i]?.cookieType == cookieType {
            i -= 1
            vertLength += 1
        }
        
        // Up
        i = row + 1
        while i < NumRows && cookies[column, i]?.cookieType == cookieType {
            i += 1
            vertLength += 1
        }
        return vertLength >= 3
    }
    
    
    // MARK: Swapping
    
    // Swaps the positions of the two cookies from the Swap object.
    func performSwap(_ swap: Swap) {
        // Need to make temporary copies of these because they get overwritten.
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        
        // Swap the cookies. We need to update the array as well as the column
        // and row properties of the Cookie objects, or they go out of sync!
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
    }
    
    // Recalculates which moves are valid.
    // In summary, this algorithm performs a swap for each pair of cookies, performs a swap
    // for each pair of cookies, checks whether it results in a china and then undoes the
    // swap, recording every chain it finds.
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let cookie = cookies[column, row] {
                    // Is it possible to swap this cookie with the one on the right?
                    // Note: don't need to check the last column.
                    if column < NumColumns - 1 {
                        
                        // Have a cookie in this spot? If there is no tile, there is no cookie.
                        if let other = cookies[column + 1, row] {
                            // Swap them
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column + 1, row: row)
                            || hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    
                    // It is possible to swap this cookie with the one above?
                    // Note: don't need to check the last row.
                    if row < NumRows - 1 {
                        
                        // Have a cookie in this spot? If there is no tile, there is no cookie.
                        if let other = cookies[column, row + 1] {
                            // Swap them
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAt(column: column, row: row + 1) ||
                               hasChainAt(column: column, row: row) {
                                set.insert(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }

    fileprivate func calculateScores(for chains: Set<Chain>) {
        // 3-chain is 30 pts, 4-chain is 60, 5-chain is 90, and so on
        for chain in chains {
            chain.score = 30 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    // Should be called at the start of every new turn.
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    
    // MARK: Detecting Matches
    
    fileprivate func detectHorizontalMatches() -> Set<Chain> {
        // Contains the Cookie objects that were part of a horizontal chain.
        // (Chain object). These cookies must be removed.
        var set = Set<Chain>()
        
        // Loop through the rows and columns.
        for row in 0..<NumRows {
            // Don't need to look at last two columns.
            var column = 0
            while column < NumColumns-2 {
                // If there is a cookie/tile at this position...
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    // And the next two columns have the same type...
                    if cookies[column + 1, row]?.cookieType == matchType &&
                       cookies[column + 2, row]?.cookieType == matchType {
                        
                        // ...then add all the cookies from this chain into the set.
                        let chain = Chain(chainType: .horizontal)
                        // Steps through all the mathcing cookies until it finds a cookie that breaks
                        // the chain or it reaches the end of the grid.
                        repeat {
                            // Adds all the matching cookies to a new Chain object.
                            chain.add(cookie: cookies[column, row]!)
                            column += 1
                        } while column < NumColumns && cookies[column, row]?.cookieType == matchType
        
                        set.insert(chain)
                        continue
                    }
                }
                // Cookie did not match or empty tile, so skip over it.
                column += 1
            }
        }
        return set
    }
    
    // Same as the horizontal version but steps through the array differently i.e. by
    // column in the outer while loop and by row in the inner loop.
    fileprivate func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows-2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column, row + 1]?.cookieType == matchType &&
                       cookies[column, row + 2]?.cookieType == matchType {
                        
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(cookie: cookies[column, row]!)
                            row += 1
                    } while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
                    set.insert(chain)
                    continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    // Detects whether there are any chains of 3 or more cookies, and removes
    // them from the level.
    // Returns a set containing Chain objects, which describes the Cookies
    // that were removed.
    func removeMatches() -> Set<Chain> {
        var horizontalChains = detectHorizontalMatches()
        var verticalChains = detectVerticalMatches()
        
        // Detects whether there are L-Shaped chains.
        // We create a new Set containing L-Shaped Chain objects.
        var lShapeChains = Set<Chain>()
        
        // We check whether a cookie is in both the horizontal & vertical
        // chains sets and whether it is the first or last in the array
        // (at a corner).
        for horizontalChain in horizontalChains {
            for verticalChain in verticalChains {
                if horizontalChain.firstCookie() == verticalChain.firstCookie() ||
                   horizontalChain.lastCookie() == verticalChain.firstCookie() ||
                   horizontalChain.firstCookie() == verticalChain.lastCookie() ||
                   horizontalChain.lastCookie() == verticalChain.lastCookie() {
                    
                    // Remove the L-Shape chains from the horizontal
                    // & vertical chains sets.
                    horizontalChains.remove(horizontalChain)
                    verticalChains.remove(verticalChain)
                    
                    // Add the horizontal part of the L-Shape
                    // chain to the vertical part & give it
                    // the .lShape chainType.
                    for cookie in horizontalChain.cookies {
                        verticalChain.add(cookie: cookie)
                    }
                    verticalChain.chainType = .lShape
                    
                    lShapeChains.insert(verticalChain)
                }
            }
        }
        
        // Detects whether there are T-Shaped chains.
        // We create a new Set containing T-Shaped Chain objects.
        var tShapeChains = Set<Chain>()
        
        // Loop through the horizontal & vertical chains.
        for horizontalChain in horizontalChains {
            for verticalChain in verticalChains {
                // We calculate the position of the middle cookie in the vertical & horizontal chains.
                let middleHorizontalCookie = horizontalChain.cookies[((horizontalChain.cookies.count) / 2)]
                let middleVerticalCookie = verticalChain.cookies[((verticalChain.cookies.count) / 2)]
                
                // We check whether a cookie is in both the horizontal & vertical
                // chains set and whether it is the in the middle in one array.
                if middleHorizontalCookie == verticalChain.firstCookie() ||
                   middleHorizontalCookie == verticalChain.lastCookie()  ||
                   middleVerticalCookie == horizontalChain.firstCookie() ||
                   middleVerticalCookie == horizontalChain.lastCookie() {
                    
                    // Remove the T-Shape chains from the horizontal
                    // & vertical chains sets.
                    horizontalChains.remove(horizontalChain)
                    verticalChains.remove(verticalChain)
                    
                    // Add the horizontal part of the T-Shape
                    // chain to the vertical part & give it
                    // the .tShape chainType.
                    for cookie in horizontalChain.cookies {
                        verticalChain.add(cookie: cookie)
                    }
                    verticalChain.chainType = .tShape
                    
                    tShapeChains.insert(verticalChain)
                }
            }
        }
        
        removeCookies(horizontalChains)
        removeCookies(verticalChains)
        removeCookies(lShapeChains)
        removeCookies(tShapeChains)
        
        // Need to call calculateScore for each set of chain objects.
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        calculateScores(for: lShapeChains)
        calculateScores(for: tShapeChains)
        
        return horizontalChains.union(verticalChains).union(lShapeChains).union(tShapeChains)
    }
    
    // Each chain has a list of cookie objects and each cookie knows its column and
    // row in the grid so you simply set that element in the array to nil to remove
    // the cookie object from the data model.
    fileprivate func removeCookies(_ chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    
    // MARK: Detecting Holes
    
    // Detects where there are holes and shifts any cookies down to fill up those
    // holes. In effect, this "bubbles" the holes up to the top of the column.
    // Returns an array that contains a sub-array for each column that had holes,
    // with the Cookie objects that have shifted. Those cookies are already
    // moved to their new position. The objects are ordered from the bottom up.
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()      // you can also write this Array<Array<Cookie>>
        
        // Loop through the rows, from bottom to top. It's handy that our row 0 is
        // at the bottom already. Because we're scanning from bottom to top, this
        // automatically causes an entire stack to fall down to fill up a hole.
        // We scan one column at a time.
        for column in 0..<NumColumns {
            var array = [Cookie]()
            for row in 0..<NumRows {
                
                // If there is a tile at this position but no cookie, then there's a hole.
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    
                    // Scan upward to find a cookie.
                    for lookup in (row + 1)..<NumRows {
                        if let cookie = cookies[column, lookup] {
                            // Swap that cookie with the hole.
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            
                            // For each column, we return an array with the cookies that have
                            // fallen down. Cookies that are lower on the screen are first in
                            // the array. We need an array to keep this order intact, so the
                            // animation code can apply the correct kind of delay.
                            array.append(cookie)
                            
                            // Don't need to scan up any further.
                            break
                        }
                    }
                }
            }

            // If a column does not have any holes, then there's no
            // point in adding it to the final array.
            if !array.isEmpty {
                columns.append(array)
            }
        }
        // Returns an array containing all the cookies that have
        // been moved down, organised by column.
        // The return type is [[Cookie]], or an array-of-array-of-cookies.
        // You can also write this as Array<Array<Cookie>>.
        return columns
    }
    
    // Where necessary, adds new cookies to fill up the holes at the top of the
    // columns.
    // Returns an array that contains a sub-array for each column that had holes,
    // with the new Cookie objects. Cookies are ordered from the top down.
    func topUpCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType: CookieType = .unknown
        
        // Detect where we have to add the new cookies. If a column has X holes,
        // then it also needs X new cookies. The holes are all on the top of the
        // column now, but the fact that there may be gaps in the tiles makes this
        // a little trickier.
        for column in 0..<NumColumns {
            var array = [Cookie]()
            
            // This time scan from top to bottom. This while loop ends when
            // cookies[column, row] is not nil - that is, when it has found a cookie.
            var row = NumRows - 1
            while row >= 0 && cookies[column, row] == nil {
                // Found a hole?
                // Ignore gaps in the level, because you only need to fill up grid
                // squares that have a tile.
                if tiles[column, row] != nil {
                    
                    // Randomly create a new cookie type. The only restriction is that
                    // it cannot be equal to the previous type. This prevents too many
                    // "freebie" matches.
                    var newCookieType: CookieType
                    repeat {
                        newCookieType = CookieType.random()
                    } while newCookieType == cookieType
                    cookieType = newCookieType
                    
                    // Create a new Cookie object and add it to the array for this column.
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
                
                row -= 1
            }
            
            // If a column does not have any holes, you don't add it to the final array.
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
}
