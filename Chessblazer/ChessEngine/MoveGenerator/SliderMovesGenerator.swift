//
//  SliderMovesGenerator.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation

func generateRookMoves(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    let blockerBitboard = occupancy.all & Rook.masks[square]
    var movesBitboard = Rook.lookUpTable[square]![magicIndex(magic: rookMagics[square], shift: rookShifts[square], blocker: blockerBitboard)]!
    var pieceValue = 0
    
    if currentColor == .white {
        movesBitboard = movesBitboard & ~occupancy.white
        pieceValue = Piece.ColoredPieces.whiteRook.rawValue
    } else {
        movesBitboard = movesBitboard & ~occupancy.black
        pieceValue = Piece.ColoredPieces.blackRook.rawValue
    }
    while movesBitboard != 0 {
        let targetSquare: Int = Bitboard.popLSB(&movesBitboard)
        moves.append(Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards)))
    }
}

func generateRookMovesForQueen(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    let blockerBitboard = occupancy.all & Rook.masks[square]
    var movesBitboard = Rook.lookUpTable[square]![magicIndex(magic: rookMagics[square], shift: rookShifts[square], blocker: blockerBitboard)]!
    var pieceValue = 0
    
    if currentColor == .white {
        movesBitboard = movesBitboard & ~occupancy.white
        pieceValue = Piece.ColoredPieces.whiteQueen.rawValue
    } else {
        movesBitboard = movesBitboard & ~occupancy.black
        pieceValue = Piece.ColoredPieces.blackQueen.rawValue
    }
    while movesBitboard != 0 {
        let targetSquare: Int = Bitboard.popLSB(&movesBitboard)
        moves.append(Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards)))
    }
}

func generateRookAttacks(square: Int, friendlyBitboard: Bitboard, occupancy: Occupancy) -> Bitboard {
    let blockerBitboard = occupancy.all & Rook.masks[square]
    var movesBitboard = Rook.lookUpTable[square]![magicIndex(magic: rookMagics[square], shift: rookShifts[square], blocker: blockerBitboard)]!
    movesBitboard = movesBitboard & ~friendlyBitboard
    return movesBitboard
}

func generateBishopMoves(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    let blockerBitboard = occupancy.all & Bishop.masks[square]
    var movesBitboard = Bishop.lookUpTable[square]![magicIndex(magic: bishopMagics[square], shift: bishopShifts[square], blocker: blockerBitboard)]!
    
    var pieceValue = 0
    if currentColor == .white {
        movesBitboard = movesBitboard & ~occupancy.white
        pieceValue = Piece.ColoredPieces.whiteBishop.rawValue
    } else {
        movesBitboard = movesBitboard & ~occupancy.black
        pieceValue = Piece.ColoredPieces.blackBishop.rawValue
    }
    
    while movesBitboard != 0 {
        let targetSquare: Int = Bitboard.popLSB(&movesBitboard)
        moves.append(Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards)))
    }
}

func generateBishopMovesForQueen(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    let blockerBitboard = occupancy.all & Bishop.masks[square]
    var movesBitboard = Bishop.lookUpTable[square]![magicIndex(magic: bishopMagics[square], shift: bishopShifts[square], blocker: blockerBitboard)]!
    
    var pieceValue = 0
    if currentColor == .white {
        movesBitboard = movesBitboard & ~occupancy.white
        pieceValue = Piece.ColoredPieces.whiteQueen.rawValue
    } else {
        movesBitboard = movesBitboard & ~occupancy.black
        pieceValue = Piece.ColoredPieces.blackQueen.rawValue
    }
    
    while movesBitboard != 0 {
        let targetSquare: Int = Bitboard.popLSB(&movesBitboard)
        moves.append(Move(fromSquare: square, targetSquare: targetSquare, pieceValue: pieceValue, captureValue: getPieceValueFromField(at: targetSquare, bitboards: bitboards)))
    }
}

func generateBishopAttacks(square: Int, friendlyBitboard: Bitboard, occupancy: Occupancy) -> Bitboard {
    let blockerBitboard = occupancy.all & Bishop.masks[square]
    var movesBitboard = Bishop.lookUpTable[square]![magicIndex(magic: bishopMagics[square], shift: bishopShifts[square], blocker: blockerBitboard)]!
    movesBitboard = movesBitboard & ~friendlyBitboard
    return movesBitboard
}

func generateQueenMoves(bitboards: PieceBitboards, currentColor: Piece.Color, square: Int, moves: inout [Move], occupancy: Occupancy) {
    var queenMoves = [Move]()
    generateRookMovesForQueen(bitboards: bitboards, currentColor: currentColor, square: square, moves: &queenMoves, occupancy: occupancy)
    generateBishopMovesForQueen(bitboards: bitboards, currentColor: currentColor, square: square, moves: &queenMoves, occupancy: occupancy)
    moves.append(contentsOf: queenMoves)
}

func generateQueenAttacks(square: Int, friendlyBitboard: Bitboard, occupancy: Occupancy) -> Bitboard {
    return generateBishopAttacks(square: square, friendlyBitboard: friendlyBitboard, occupancy: occupancy)
        | generateRookAttacks(square: square, friendlyBitboard: friendlyBitboard, occupancy: occupancy)
}
