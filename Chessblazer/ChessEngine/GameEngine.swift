//
//  GameEngine.swift
//  Chessblazer
//
//  Created by sergiusz on 11/10/2024.
//

import Foundation

class GameEngine {
    
    static func makeMoveOnly(boardState: BoardState, move: Move) -> BoardState {
        var boardStateCopy = boardState
        boardStateCopy.applyBitboards(move)
        boardStateCopy.refreshOccupancy()
        boardStateCopy.attackBitboard = generateAllAttackedSquares(
            bitboards: boardStateCopy.bitboards,
            currentColor: boardStateCopy.currentTurnColor,
            occupancy: boardStateCopy.occupancy
        )
        return boardStateCopy
    }
    
    static func loadBoardFromFen(fen: String) -> BoardState {
        var boardState = BoardState(currentTurnColor: .white)
        let args = fen.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if args.count > 1 {
            boardState.currentTurnColor = args[1] == "w" ? .white : .black
        }
        boardState.castlesAvailable.removeAll()
        if args.count > 2 {
            for letter in args[2] {
                if letter == "-" { break } else { boardState.castlesAvailable.insert(letter) }
            }
        }
        if args.count > 3 {
            boardState.enPassant = args[3]
        }
        let ranks: [String] = (args.first ?? "").components(separatedBy: "/")
        var index = 0
        for rank in ranks.reversed() {
            
            for char in rank {
                if char.isNumber {
                    for _ in 0..<char.wholeNumberValue! {
                        index+=1
                    }
                } else {
                    let piece: Int = Piece.combine(type: Piece.PiecesDict[char.lowercased().first!] ?? Piece.PieceType.empty, color: char.isUppercase ? Piece.Color.white : Piece.Color.black)
                    
                    boardState.bitboards.addPiece(piece, at: index)
                    index+=1
                }
            }
        }
        
        boardState.refreshOccupancy()
        boardState.refreshZobristKey()
        return boardState
    }
}
