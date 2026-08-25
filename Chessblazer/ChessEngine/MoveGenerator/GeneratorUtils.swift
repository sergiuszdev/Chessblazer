//
//  GeneratorUtils.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation

func emptySquaresBitboard(bitboards: PieceBitboards) -> Bitboard {
    return ~bitboards.occupancy().all
}

func getKingBitboard(bitboards: PieceBitboards, color: Piece.Color) -> Bitboard {
    if color == .white {
        return bitboards[Piece.ColoredPieces.whiteKing.rawValue]
    } else {
        return bitboards[Piece.ColoredPieces.blackKing.rawValue]
    }
}

func getPieceValueFromField(at field: Int, bitboards: PieceBitboards) -> Int {
    let b = Bitboard(1) << Bitboard(field)
    var captured = 0
    bitboards.forEachOccupied { piece, board in
        if captured == 0 && b & board == b {
            captured = piece
        }
    }
    return captured
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
