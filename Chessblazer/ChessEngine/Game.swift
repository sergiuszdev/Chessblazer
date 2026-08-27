//
//  Board.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

public final class Game {
    
    public var boardData = BoardData()
    public var boardState = BoardState(currentTurnColor: .white)
    
    public init() {
        startNewGame()
    }
    
    public func loadFromFen(fen: String) {
        boardState = GameEngine.loadBoardFromFen(fen: fen)
        refreshDerivedState()
    }
    
    public func startNewGame() {
        loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }
    
    public func makeMove(move: Move) {
        boardState.play(move, snapshotLegalMoves: true)
        refreshDerivedState()
    }
    
    public func undoMove() {
        boardState.unplay()
        updateGameResult()
    }
    
    public func play(_ move: Move) {
        boardState.play(move, snapshotLegalMoves: false)
    }
    
    public func playNull() {
        boardState.playNull()
    }
    
    public func unplay() {
        boardState.unplay()
    }
    
    public func findMove(notation: String) -> Move? {
        let parsed = Move(notation: notation)
        guard parsed.fromSquare != nil, parsed.targetSquare != nil else { return nil }
        return boardState.currentValidMoves.first { legal in
            legal.fromSquare == parsed.fromSquare
            && legal.targetSquare == parsed.targetSquare
            && (parsed.promotionPiece == 0
                || Piece.getType(piece: parsed.promotionPiece) == Piece.getType(piece: legal.promotionPiece))
        }
    }
    
    public func toBoardArrayRepresentation() -> [Int] {
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
        updateGameResult()
    }
    
    private func updateGameResult() {
        if boardState.currentValidMoves.isEmpty {
            boardData.hasGameEnded = true
            if isWhiteKingChecked(boardState: boardState) {
                boardData.gameResult = .black
            } else if isBlackKingChecked(boardState: boardState) {
                boardData.gameResult = .white
            } else {
                boardData.gameResult = .draw
            }
        } else if boardState.isRepetitionDraw() || boardState.isFiftyMoveDraw(hasLegalMoves: true) {
            boardData.hasGameEnded = true
            boardData.gameResult = .draw
        } else {
            boardData.hasGameEnded = false
            boardData.gameResult = .none
        }
        boardData.halfMoves = boardState.halfmoveClock
    }
}
