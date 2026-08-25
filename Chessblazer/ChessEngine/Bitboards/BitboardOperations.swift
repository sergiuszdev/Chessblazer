//
//  BitboardOperations.swift
//  Chessblazer
//
//  Created by sergiusz on 29/07/2024.
//

import Foundation

extension Bitboard {
    func eastOne() -> Bitboard {
        return (self << 1) & ~Bitboard.Masks.fileA
    }
    
    func westOne() -> Bitboard {
        return (self >> 1) & ~Bitboard.Masks.fileH
    }
    
    func northOne() -> Bitboard {
        return self << 8
    }
    
    func southOne() -> Bitboard {
        return self >> 8
    }
    
    static func popLSB(_ bitboard: inout Bitboard) -> Int {
        let lsb = bitboard & (~bitboard + 1)
        bitboard = bitboard & ~Bitboard(lsb)
        return lsb.trailingZeroBitCount
    }
}
