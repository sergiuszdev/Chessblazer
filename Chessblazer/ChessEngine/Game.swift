//
//  Board.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

class Game {
    
    var boardData = BoardData()
    var boardState = BoardState(currentTurnColor: .white)
    
    init() {
        startNewGame()
    }
    
    func loadFromFen(fen: String) {
        boardState = GameEngine.loadBoardFromFen(fen: fen)
        boardState.currentValidMoves = generateAllLegalMoves(boardState: boardState)
        boardState.attackBitboard = generateAllAttackedSquares(bitboards: boardState.bitboards, currentColor: boardState.currentTurnColor)
    }
    
    func startNewGame() {
        loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }
    
    func makeMove(move: Move) {
        
        boardState.performedMovesList.append(
            MoveData(
                piece: move.pieceValue,
                turn: 0,
                color: boardState.currentTurnColor,
                move: move,
                capturedPiece: move.captureValue,
                bitboards: boardState.bitboards,
                castles: boardState.castlesAvailable,
                currentValidMoves: boardState.currentValidMoves,
                attackBitboard: boardState.attackBitboard
            ))
        
        
        boardState = GameEngine.makeMove(boardState: boardState, move: move)
        boardState.currentTurnColor = boardState.currentTurnColor.getOppositeColor()
        boardState.currentValidMoves = generateAllLegalMoves(boardState: boardState)
        boardState.attackBitboard = generateAllAttackedSquares(bitboards: boardState.bitboards, currentColor: boardState.currentTurnColor)
        
        
        if boardState.currentValidMoves.isEmpty {
            boardData.hasGameEnded = true
            if isWhiteKingChecked(boardState: boardState) {
                boardData.gameResult = .black
            } else if isBlackKingChecked(boardState: boardState) {
                boardData.gameResult = .white
            } else {
                boardData.gameResult = .draw
            }
        }
    }
    
    func undoMove() {
        guard let moveData = boardState.performedMovesList.popLast() else { return }
        boardState.bitboards = moveData.bitboards
        boardState.castlesAvailable = moveData.castles
        boardState.currentTurnColor = moveData.color
        boardState.currentValidMoves = moveData.currentValidMoves
        boardState.attackBitboard = moveData.attackBitboard
        
        
        if !boardState.currentValidMoves.isEmpty {
            boardData.hasGameEnded = false
            boardData.gameResult = .none
        }
    }
    
    func findMove(notation: String) -> Move? {
        let parsed = Move(notation: notation)
        guard parsed.fromSquare != nil, parsed.targetSquare != nil else { return nil }
        return boardState.currentValidMoves.first { legal in
            legal.fromSquare == parsed.fromSquare
            && legal.targetSquare == parsed.targetSquare
            && (parsed.promotionPiece == 0
                || Piece.getType(piece: parsed.promotionPiece) == Piece.getType(piece: legal.promotionPiece))
        }
    }
    
    
    func toBoardArrayRepresentation() -> [Int] {
        var array = Array(repeating: 0, count: 64)
        let copy = boardState.bitboards
        
        for bitboard in copy {
            var pieceBitboard = bitboard.value
            while pieceBitboard != 0 {
                let piece = bitboard.key
                let index = Bitboard.popLSB(&pieceBitboard)
                
                array[index] = piece
            }
        }
        return array
    }
}
