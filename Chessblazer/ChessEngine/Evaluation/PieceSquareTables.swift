//
//  PieceSquareTables.swift
//  Chessblazer
//
//  Created by sergiusz on 06/08/2024.
//

import Foundation

extension Array where Element == Int {
    func mirrored() -> [Int] {
        var mirroredTable = [Int]()
        for i in stride(from: 56, through: 0, by: -8) {
            mirroredTable.append(contentsOf: self[i..<i+8])
        }
        return mirroredTable
    }
}

enum GamePhase {
    /// Startpos non-pawn material: 4 knights + 4 bishops + 4 rooks + 2 queens = 24.
    static let full = 24
    
    static func weight(for piece: Int) -> Int {
        switch Piece.getType(piece: piece) {
        case .knight, .bishop: return 1
        case .rook: return 2
        case .queen: return 4
        default: return 0
        }
    }
    
    static func of(_ bitboards: PieceBitboards) -> Int {
        var phase = 0
        bitboards.forEachOccupied { piece, board in
            let unit = weight(for: piece)
            if unit != 0 {
                phase += unit * board.nonzeroBitCount
            }
        }
        return min(phase, full)
    }
    
    static func interpolate(middlegame: Int, endgame: Int, phase: Int) -> Int {
        let clamped = min(Swift.max(phase, 0), full)
        return (middlegame * clamped + endgame * (full - clamped)) / full
    }
}

struct PieceSquareTables {
    static func getTable(piece: Int, phase: Int = GamePhase.full) -> [Int] {
        if Piece.getType(piece: piece) == .king {
            return (0..<64).map { pieceSquareValue(piece: piece, square: $0, phase: phase) }
        }
        
        switch Piece.ColoredPieces(rawValue: piece) {

        case .some(.empty):
            return [Int]()
        case .some(.blackPawn):
            return pawnTable.mirrored()
        case .some(.blackQueen):
            return queenTable.mirrored()
        case .some(.blackKnight):
            return knightTable.mirrored()
        case .some(.blackBishop):
            return bishopTable.mirrored()
        case .some(.blackRook):
            return rookTable.mirrored()
        case .some(.whitePawn):
            return pawnTable
        case .some(.whiteQueen):
            return queenTable
        case .some(.whiteKnight):
            return knightTable
        case .some(.whiteBishop):
            return bishopTable
        case .some(.whiteRook):
            return rookTable
        default:
            return [Int]()
        }
    }
    
    static func pieceSquareValue(piece: Int, square: Int, phase: Int) -> Int {
        guard (0..<64).contains(square) else { return 0 }
        if Piece.getType(piece: piece) == .king {
            let index = Piece.checkColor(piece: piece) == .white ? square : square ^ 56
            return GamePhase.interpolate(
                middlegame: kingMidgameTable[index],
                endgame: kingEndgameTable[index],
                phase: phase
            )
        }
        let table = getTable(piece: piece)
        guard square < table.count else { return 0 }
        return table[square]
    }
    
    static let pawnTable: [Int] = [
        0,  0,  0,  0,  0,  0,  0,  0,
        5, 10, 10,-20,-20, 10, 10,  5,
        5, -5,-10,  0,  0,-10, -5,  5,
        0,  0,  0, 20, 20,  0,  0,  0,
        5,  5, 10, 25, 25, 10,  5,  5,
        10, 10, 20, 30, 30, 20, 10, 10,
        50, 50, 50, 50, 50, 50, 50, 50,
        0,  0,  0,  0,  0,  0,  0,  0,
    ]
    
    static let knightTable: [Int] = [
        -50,-40,-30,-30,-30,-30,-40,-50,
         -40,-20,  0,  5,  5,  0,-20,-40,
         -30,  5, 10, 15, 15, 10,  5,-30,
         -30,  0, 15, 20, 20, 15,  0,-30,
         -30,  5, 15, 20, 20, 15,  5,-30,
         -30,  0, 10, 15, 15, 10,  0,-30,
         -40,-20,  0,  0,  0,  0,-20,-40,
         -50,-40,-30,-30,-30,-30,-40,-50,
    ]
    
    static let bishopTable: [Int] = [
        -20,-10,-10,-10,-10,-10,-10,-20,
         -10,  5,  0,  0,  0,  0,  5,-10,
         -10, 10, 10, 10, 10, 10, 10,-10,
         -10,  0, 10, 10, 10, 10,  0,-10,
         -10,  5,  5, 10, 10,  5,  5,-10,
         -10,  0,  5, 10, 10,  5,  0,-10,
         -10,  0,  5, 10, 10,  5,  0,-10,
         -20,-10,-10,-10,-10,-10,-10,-20,
    ]
    
    static let rookTable: [Int] = [
        0,  0,  0,  5,  5,  0,  0,  0,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        5, 10, 10, 10, 10, 10, 10,  5,
        0,  0,  0,  0,  0,  0,  0,  0,
    ]
    
    static let queenTable: [Int] = [
        -20,-10,-10, -5, -5,-10,-10,-20,
         -10,  0,  5,  0,  0,  0,  0,-10,
         -10,  5,  5,  5,  5,  5,  0,-10,
         0,  0,  5,  5,  5,  5,  0, -5,
         -5,  0,  5,  5,  5,  5,  0, -5,
         -10,  0,  5,  5,  5,  5,  0,-10,
         -10,  0,  0,  0,  0,  0,  0,-10,
         -20,-10,-10, -5, -5,-10,-10,-20,
    ]
    
    static let kingMidgameTable: [Int] = [
        20, 30, 10,  0,  0, 10, 30, 20,
        20, 20,  0,  0,  0,  0, 20, 20,
        -10,-20,-20,-20,-20,-20,-20,-10,
        -20,-30,-30,-40,-40,-30,-30,-20,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
    ]
    
    static let kingEndgameTable: [Int] = [
        0,  10,  20,  30,  30,  20,  10,   0,
       10,  20,  30,  40,  40,  30,  20,  10,
       20,  30,  40,  50,  50,  40,  30,  20,
       30,  40,  50,  60,  60,  50,  40,  30,
       30,  40,  50,  60,  60,  50,  40,  30,
       20,  30,  40,  50,  50,  40,  30,  20,
       10,  20,  30,  40,  40,  30,  20,  10,
        0,  10,  20,  30,  30,  20,  10,   0
    ]
}
