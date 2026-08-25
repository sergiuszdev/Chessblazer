//
//  GeneratorUtils.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation
func emptySquaresBitboard(bitboards: [Int: Bitboard]) -> Bitboard {
    var notEmpty = Bitboard(0)
    for bitboard in bitboards {
        notEmpty = notEmpty | bitboard.value
    }
    
    return ~notEmpty
}

func getKingBitboard(bitboards: [Int: Bitboard], color: Piece.Color) -> Bitboard {
    
    if color == .white {
        return bitboards[Piece.ColoredPieces.whiteKing.rawValue]!
    } else {
        return bitboards[Piece.ColoredPieces.blackKing.rawValue]!
    }
    
}

func getPieceValueFromField(at field: Int, bitboards: [Piece.ColoredPieces.RawValue: Bitboard]) -> Piece.ColoredPieces.RawValue {
    let b = Bitboard(1) << Bitboard(field)
    for bitboard in bitboards {
        if b & bitboard.value == b {
            return bitboard.key
        }
    }
    return 0 // no capture
}

func checkIfCheck(boardState: BoardState) -> Bool {
    let attackTable = boardState.attackBitboard
    let kingBitboard = getKingBitboard(bitboards: boardState.bitboards, color: boardState.currentTurnColor)
    return (attackTable & kingBitboard) != 0
}

func isWhiteKingChecked(boardState: BoardState) -> Bool {
    let attackTable = generateAllAttackedSquares(bitboards: boardState.bitboards, currentColor: .white)
    let kingBitboard = getKingBitboard(bitboards: boardState.bitboards, color: .white)
    return (attackTable & kingBitboard) != 0
}

func isBlackKingChecked(boardState: BoardState) -> Bool {
    let attackTable = generateAllAttackedSquares(bitboards: boardState.bitboards, currentColor: .black)
    let kingBitboard = getKingBitboard(bitboards: boardState.bitboards, color: .black)
    return (attackTable & kingBitboard) != 0
}
