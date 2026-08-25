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
        refreshDerivedState()
    }
    
    func startNewGame() {
        loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }
    
    func makeMove(move: Move) {
        boardState.play(move, snapshotLegalMoves: true)
        refreshDerivedState()
    }
    
    func undoMove() {
        boardState.unplay()
        if !boardState.currentValidMoves.isEmpty {
            boardData.hasGameEnded = false
            boardData.gameResult = .none
        }
    }
    
    func play(_ move: Move) {
        boardState.play(move, snapshotLegalMoves: false)
    }
    
    func playNull() {
        boardState.playNull()
    }
    
    func unplay() {
        boardState.unplay()
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
        boardState.bitboards.forEachOccupied { piece, board in
            var pieceBitboard = board
            while pieceBitboard != 0 {
                let index = Bitboard.popLSB(&pieceBitboard)
                array[index] = piece
            }
        }
        return array
    }
    
    private func refreshDerivedState() {
        boardState.refreshOccupancy()
        boardState.attackBitboard = generateAllAttackedSquares(
            bitboards: boardState.bitboards,
            currentColor: boardState.currentTurnColor,
            occupancy: boardState.occupancy
        )
        boardState.currentValidMoves = generateAllLegalMoves(boardState: boardState)
        if boardState.currentValidMoves.isEmpty {
            boardData.hasGameEnded = true
            if isWhiteKingChecked(boardState: boardState) {
                boardData.gameResult = .black
            } else if isBlackKingChecked(boardState: boardState) {
                boardData.gameResult = .white
            } else {
                boardData.gameResult = .draw
            }
        } else {
            boardData.hasGameEnded = false
            boardData.gameResult = .none
        }
    }
}
