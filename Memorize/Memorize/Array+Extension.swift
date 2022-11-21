//
//  Array+Extension.swift
//  Memorize
//
//  Created by estaife on 16/11/22.
//

import Foundation

extension Array {
    var oneAndOnly: Element? {
        if count == 1 {
            return first
        } else {
            return nil
        }
    }
}
