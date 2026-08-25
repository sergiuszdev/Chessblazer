//
//  KingMovesGenerator.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation

func generateKingMovesBitboard(bitboards: [Int: Bitboard], currentColor: Piece.Color, moves: inout [Move], occupancy: Occupancy, attackedSquares: Bitboard) {
    var kingBitboard = Bitboard(0)
    var pieceValue = 0
    
    if currentColor == .white {
        kingBitboard = bitboards[Piece.ColoredPieces.whiteKing.rawValue]!
        pieceValue = Piece.ColoredPieces.whiteKing.rawValue
    } else {
        kingBitboard = bitboards[Piece.ColoredPieces.blackKing.rawValue]!
        pieceValue = Piece.ColoredPieces.blackKing.rawValue
    }
    let friendlyMask = occupancy.friendly(for: currentColor)
    
    while kingBitboard != 0 {
        let square = Bitboard.popLSB(&kingBitboard)
        let king = Bitboard(1) << Bitboard(square)
        var movesBitboard = generateKingAttacks(king: king) & ~friendlyMask & ~attackedSquares
        
        while movesBitboard != 0 {
            let targetSquare = Bitboard.popLSB(&movesBitboard)
            let move = Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards))
            moves.append(move)
        }
    }
}

func generateCastles(bitboards: [Int: Bitboard], currentColor: Piece.Color, moves: inout [Move], castlesAvailable: Set<Character>, occupancy: Occupancy, attackedSquares: Bitboard) {
    if currentColor == .white {
        let kingBitboard = bitboards[Piece.ColoredPieces.whiteKing.rawValue]!
        let friendlyMask = occupancy.all



        let isUnderAttack = kingBitboard & attackedSquares != 0
        if !isUnderAttack {
            
            let rooksBitboard = bitboards[Piece.ColoredPieces.whiteRook.rawValue]!
            

            let piecesRank1 = friendlyMask & Bitboard.Masks.rank1
            let rooksKing = rooksBitboard | kingBitboard
            
            let rightRookToKing = Bitboard(144)
            let rightCorrectPositions = rooksKing & rightRookToKing == rightRookToKing
            let isRightPathClear = Bitboard(96) & piecesRank1 == 0
            let isRightPathNotUnderAttack = attackedSquares & Bitboard(96) == 0
            let isRightPossible = isRightPathClear && isRightPathNotUnderAttack && rightCorrectPositions

            
            let leftRookToKing = Bitboard(17)
            let leftCorrectPositions = rooksKing & leftRookToKing == leftRookToKing
            let isLeftPathClear = Bitboard(14) & piecesRank1 == 0
            let isLeftPathNotUnderAttack = attackedSquares & Bitboard(12) == 0
            let isLeftPossible = isLeftPathClear && isLeftPathNotUnderAttack && leftCorrectPositions
            
            
            if isRightPossible && castlesAvailable.contains("K") {
                moves.append(Move(
                    kingFrom: 4, kingTo: 6, rookFrom: 7, rookTo: 5,
                    kingValue: Piece.ColoredPieces.whiteKing.rawValue,
                    rookValue: Piece.ColoredPieces.whiteRook.rawValue
                ))
            }
            
            if isLeftPossible && castlesAvailable.contains("Q") {
                moves.append(Move(
                    kingFrom: 4, kingTo: 2, rookFrom: 0, rookTo: 3,
                    kingValue: Piece.ColoredPieces.whiteKing.rawValue,
                    rookValue: Piece.ColoredPieces.whiteRook.rawValue
                ))
            }
        }
        
    } else {
        let kingBitboard = bitboards[Piece.ColoredPieces.blackKing.rawValue]!
        let friendlyMask = occupancy.all
        let isUnderAttack = kingBitboard & attackedSquares != 0

        if !isUnderAttack {
            let rooksBitboard = bitboards[Piece.ColoredPieces.blackRook.rawValue]!
            let piecesRank8 = friendlyMask & Bitboard.Masks.rank8
            let rooksKing = rooksBitboard | kingBitboard
            
            let rightRookToKing = Bitboard(10376293541461622784)
            let rightCorrectPositions = rooksKing & rightRookToKing == rightRookToKing
            let isRightPathClear = Bitboard(6917529027641081856) & piecesRank8 == 0
            let isRightPathNotUnderAttack = attackedSquares & Bitboard(6917529027641081856) == 0
            let isRightPossible = isRightPathClear && isRightPathNotUnderAttack && rightCorrectPositions

            let leftRookToKing = Bitboard(1224979098644774912)
            let leftCorrectPositions = rooksKing & leftRookToKing == leftRookToKing
            let isLeftPathClear = Bitboard(1008806316530991104) & piecesRank8 == 0
            let isLeftPathNotUnderAttack = attackedSquares & Bitboard(864691128455135232) == 0
            let isLeftPossible = isLeftPathClear && isLeftPathNotUnderAttack && leftCorrectPositions
            
            if isRightPossible && castlesAvailable.contains("k") {
                moves.append(Move(
                    kingFrom: 60, kingTo: 62, rookFrom: 63, rookTo: 61,
                    kingValue: Piece.ColoredPieces.blackKing.rawValue,
                    rookValue: Piece.ColoredPieces.blackRook.rawValue
                ))
            }
            
            if isLeftPossible && castlesAvailable.contains("q") {
                moves.append(Move(
                    kingFrom: 60, kingTo: 58, rookFrom: 56, rookTo: 59,
                    kingValue: Piece.ColoredPieces.blackKing.rawValue,
                    rookValue: Piece.ColoredPieces.blackRook.rawValue
                ))
            }
        }
    }
}

func generateKingAttacks(king: Bitboard) -> Bitboard {
    var attacks = king.eastOne() | king.westOne()
    let kingSet = king | attacks
    attacks = attacks | (kingSet.northOne() | kingSet.southOne())
    return attacks
}
func generateKingAttacks(square: Int, friendlyBitboard: Bitboard) -> Bitboard {
    
    var kingBitboard = Bitboard(1) << Bitboard(square)
    
    let square = Bitboard.popLSB(&kingBitboard)
    let king = Bitboard(1) << Bitboard(square)
    let movesBitboard = generateKingAttacks(king: king) & ~friendlyBitboard
    return movesBitboard
    
}
