//
//  GameState.swift
//  ChessblazerGUI
//
//  Created by sergiusz on 03/08/2024.
//

import Foundation

@Observable
class GameState {
    var game = Game()
    var evaluation = 0
    var indexOfTappedPiece: Int = -1
    var tappedPieceTargets = [Int]()
    var attackTable = [Int]()
    var validMoves = [Move]()
    var currentColorToMove = Piece.Color.white
    var boardArray: [Int] = Array(repeating: 0, count: 64)
    
    func startNewGame() {
        game = Game()
        validMoves.removeAll()
        currentColorToMove = Piece.Color.white
        tappedPieceTargets.removeAll()
        validMoves = game.boardState.currentValidMoves
        boardArray = game.toBoardArrayRepresentation()
    }
    func loadFenGame(fen: String) {
        game.loadFromFen(fen: fen)
        boardArray = game.toBoardArrayRepresentation()
    }
    
    func onPieceTap(square: Int) {
        if tappedPieceTargets.contains(square) {
            if currentColorToMove == Piece.checkColor(piece: game.toBoardArrayRepresentation()[indexOfTappedPiece]) {
                makeMove(indexOfTappedPiece, square)
            }
            tappedPieceTargets.removeAll()
        } else {
            indexOfTappedPiece = square
            tappedPieceTargets = validTargetSquares(fromSquare: square)
        }
}

    func makeMove(_ from: Int, _ to: Int) {
        tappedPieceTargets.removeAll()
        
        for move in validMoves {
            if move.fromSquare == from && move.targetSquare == to {
                game.makeMove(move: move)
                validMoves = game.boardState.currentValidMoves
                currentColorToMove = game.boardState.currentTurnColor
                var bits = game.boardState.attackBitboard
                boardArray = game.toBoardArrayRepresentation()
                attackTable.removeAll()
                while bits != 0 {
                    let x = UInt64.popLSB(&bits)
                    attackTable.append(x)
                }
                break
            }
        }
    }

    func startPvE() async {
        while !game.boardData.hasGameEnded {
            if game.boardState.currentTurnColor == .black {
                let bestMove = findBestMove(game: game, depth: 3, maximizingPlayer: game.boardState.currentTurnColor == .white ? true : false)
                makeMove(bestMove!.fromSquare!, bestMove!.targetSquare!)
                DispatchQueue.main.async {
                    self.boardArray = self.game.toBoardArrayRepresentation()
                }
            }

        }
    }
    
    func startEvE() async {
        while !game.boardData.hasGameEnded {
            let bestMove = findBestMove(game: game, depth: 3, maximizingPlayer: game.boardState.currentTurnColor == .white ? true : false)
            game.makeMove(move: bestMove!)
            DispatchQueue.main.async {
                self.boardArray = self.game.toBoardArrayRepresentation()
            }
        }
    }
    
    func validTargetSquares(fromSquare: Int) -> [Int] {
        var targets = [Int]()
        for move in validMoves where (move.fromSquare != nil && move.targetSquare != nil && move.fromSquare == fromSquare) {
            targets.append(move.targetSquare!)
        }
        return targets
    }
    
    func undoneMove() {

        game.undoMove()
        currentColorToMove = game.boardState.currentTurnColor
        tappedPieceTargets.removeAll()
        validMoves = game.boardState.currentValidMoves
        boardArray = game.toBoardArrayRepresentation()
        evaluation = evaluate(bitboards: game.boardState.bitboards)
    }
}
