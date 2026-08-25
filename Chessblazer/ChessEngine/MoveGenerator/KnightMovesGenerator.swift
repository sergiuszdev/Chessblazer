//
//  KnightMovesGenerator.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation


func generateKnightMoves(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    var knightBitboard = Bitboard(1) << Bitboard(square)
    var pieceValue = 0
    let friendlyMask = occupancy.friendly(for: currentColor)
    if currentColor == .white {
        pieceValue = Piece.ColoredPieces.whiteKnight.rawValue
    } else {
        pieceValue = Piece.ColoredPieces.blackKnight.rawValue
    }
    
    while knightBitboard != 0 {
        let square = Bitboard.popLSB(&knightBitboard)
        let knight = Bitboard(1) << Bitboard(square)
        var movesBitboard = generateKnightAttacks(bitboard: knight) & ~friendlyMask
        while movesBitboard != 0 {
            let targetSquare = Bitboard.popLSB(&movesBitboard)
            moves.append(Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards)))
        }
    }
}

func generateKnightAttacks(bitboard: UInt64) -> UInt64 {
    
    let firstHalf: UInt64 = ((bitboard << 15) | (bitboard >> 17)) & ~Bitboard.Masks.fileH |
    ((bitboard << 17) | (bitboard >> 15)) & ~Bitboard.Masks.fileA
    
    let secondHalf: UInt64 = ((bitboard << 6) | (bitboard >> 10)) & ~Bitboard.Masks.fileGH |
    ((bitboard << 10) | (bitboard >> 6)) & ~Bitboard.Masks.fileAB
    
    return firstHalf | secondHalf
}

func generateKnightAttacks(square: Int, friendlyBitboard: Bitboard) -> Bitboard {
    var knightBitboard = Bitboard(1) << Bitboard(square)
    let square = Bitboard.popLSB(&knightBitboard)
    let knight = Bitboard(1) << Bitboard(square)
    let movesBitboard = generateKnightAttacks(bitboard: knight) & ~friendlyBitboard
    return movesBitboard
}
