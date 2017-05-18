//
//  Array2D.swift
//  BakeryBlast
//
//  Created by George Irons on 10/05/2017.
//  Copyright © 2017 Girons. All rights reserved.
//

// The notation Array2D<T> means that this struct is a generic; it can
// hold elements of any type T.
struct Array2D<T> {
    
    let columns: Int
    let rows: Int
    fileprivate var array: Array<T?>
    
    // Array2D's initializer creates a regular Swift Array with a count of
    // rows x columns and sets all these elements to nil.
    // When you want a value to be nil in Swift, it needs to be declared
    // optional, which is why the type of the array property is Array<T?>
    // and not just Array<T>.
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: nil, count: rows*columns)
    }
    
    // What makes Array2D easy to use is that it supports subscripting. If
    // you know the column and row numbers of a specific item, you can index
    // the array as follows: myCookie = cookies[column, row].
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
    
}
