//
//  Magic.swift
//  Chessblazer
//
//  Created by sergiusz on 30/07/2024.
//

import Foundation

class Magic {
    
    static func whitePiecesBitboards(bitboards: PieceBitboards) -> Bitboard {
        bitboards.occupancy().white
    }
    
    static func blackPiecesBitboards(bitboards: PieceBitboards) -> Bitboard {
        bitboards.occupancy().black
    }
    
    static func allPieces(bitboards: PieceBitboards) -> Bitboard {
        bitboards.occupancy().all
    }
    
    static func createAllBlockers(movementMask: Bitboard) -> [Bitboard] {
        var indexesToCheck = [Int]()
        var mask = movementMask
        
        while mask != 0 {
            indexesToCheck.append(Bitboard.popLSB(&mask))
        }
        
        let numberOfDiffBitboards = 1 << indexesToCheck.count
        var blockers = Array(repeating: Bitboard(0), count: numberOfDiffBitboards)
        
        for patternIndex in 0..<numberOfDiffBitboards {
            for bitIndex in 0..<indexesToCheck.count {
                let bit = (patternIndex >> bitIndex) & 1
                blockers[patternIndex] = blockers[patternIndex] | (Bitboard(bit) << Bitboard(indexesToCheck[bitIndex]))
            }
        }
        return blockers
    }
}
