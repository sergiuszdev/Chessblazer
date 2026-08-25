//
//  BoardState.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation

struct Occupancy: Equatable {
    var white: Bitboard = 0
    var black: Bitboard = 0
    
    var all: Bitboard { white | black }
    
    func friendly(for color: Piece.Color) -> Bitboard {
        color == .white ? white : black
    }
    
    func enemy(for color: Piece.Color) -> Bitboard {
        color == .white ? black : white
    }
    
    static func from(bitboards: [Int: Bitboard]) -> Occupancy {
        var occupancy = Occupancy()
        for (piece, board) in bitboards {
            if Piece.checkColor(piece: piece) == .white {
                occupancy.white |= board
            } else {
                occupancy.black |= board
            }
        }
        return occupancy
    }
}

struct BoardState {
    var attackBitboard = Bitboard(0)
    var occupancy = Occupancy()
    var performedMovesList = [MoveData]()
    var castlesAvailable: Set<Character> = []
    var currentTurnColor: Piece.Color // = .white
    var bitboards: [Int: Bitboard] = initBitboards()
    var enPassant = "-"
    var currentValidMoves: [Move] = [Move]()
    
    mutating func refreshOccupancy() {
        occupancy = Occupancy.from(bitboards: bitboards)
    }
}

func initBitboards() -> [Int: Bitboard] {
    var bitboards = [Piece.ColoredPieces.RawValue : Bitboard]()
    for piece in Piece.ColoredPieces.allCases {
        if piece.rawValue != 0 {
            bitboards[piece.rawValue] = Bitboard(0)
        }
    }
    return bitboards
}

enum GameResult {
    case white, black, draw, none
}

struct BoardData {
    var halfMoves = 0
    var hasGameEnded = false
    var gameResult: GameResult = .none
}

struct MoveData {
    var piece: Int
    var turn: Int
    var color: Piece.Color
    var move: Move
    var capturedPiece: Int?
    var bitboards: [Piece.ColoredPieces.RawValue : Bitboard]
    var castles: Set<Character>
    var currentValidMoves: [Move]
    var attackBitboard = Bitboard(0)
}


