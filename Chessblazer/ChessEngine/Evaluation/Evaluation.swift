//
//  Evaluation.swift
//  Chessblazer
//
//  Created by sergiusz on 06/08/2024.
//

import Foundation

let timeLimit: TimeInterval = 0.01

func isTimeLimitExceeded(searchStartTime: TimeInterval) -> Bool {
    return Date().timeIntervalSince1970 - searchStartTime >= timeLimit
}
let MATE_VALUE = 50000
let PieceValueTable: [Int: Int] = [
    Piece.ColoredPieces.empty.rawValue : 0,
    Piece.ColoredPieces.whitePawn.rawValue : 100,
    Piece.ColoredPieces.whiteKnight.rawValue : 320,
    Piece.ColoredPieces.whiteBishop.rawValue : 330,
    Piece.ColoredPieces.whiteRook.rawValue : 500,
    Piece.ColoredPieces.whiteQueen.rawValue : 900,
    Piece.ColoredPieces.whiteKing.rawValue : 20000,
    
    Piece.ColoredPieces.blackPawn.rawValue : -100,
    Piece.ColoredPieces.blackKnight.rawValue : -320,
    Piece.ColoredPieces.blackBishop.rawValue : -330,
    Piece.ColoredPieces.blackRook.rawValue : -500,
    Piece.ColoredPieces.blackQueen.rawValue : -900,
    Piece.ColoredPieces.blackKing.rawValue : -20000,
]
func countMaterial(bitboards: [Int: Bitboard]) -> Int {
    var whiteSum = 0
    var blackSum = 0
    for (piece, bitboard) in bitboards where piece > 0 {
        let table = PieceSquareTables.getTable(piece: piece)
        let pieceValue = PieceValueTable[piece] ?? 0
        var bitboardCopy = bitboard
        while bitboardCopy != 0 {
            let position = Bitboard.popLSB(&bitboardCopy)
            if Piece.checkColor(piece: piece) == .white {
                whiteSum += pieceValue + table[position]
            } else {
                blackSum += pieceValue - table[position]
            }
        }
    }
    return whiteSum + blackSum
}

func evaluate(bitboards: [Int: Bitboard]) -> Int {
    return countMaterial(bitboards: bitboards)
}

func alphabeta(game: Game, depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
    var alpha = alpha
    var beta = beta

    if depth == 0 {
        
        if game.boardState.currentValidMoves.isEmpty {
            if isWhiteKingChecked(boardState: game.boardState) {
                return MATE_VALUE
            } else if isBlackKingChecked(boardState: game.boardState) {
                return -MATE_VALUE
            } else {
                return 0 //draw
            }
        }
        return evaluate(bitboards: game.boardState.bitboards)
    }
    let moves = game.boardState.currentValidMoves
    if maximizingPlayer {
        var maxEval = Int.min
        for move in moves {
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            game.undoMove()

            maxEval = max(maxEval, eval)
            alpha = max(alpha, maxEval)
            if beta <= alpha {
                break
            }
        }
        return maxEval
    } else {
        var minEval = Int.max
        for move in moves {
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true)
            game.undoMove()

            minEval = min(minEval, eval)
            beta = min(beta, minEval)
            if beta <= alpha {
                break
            }
        }
        return minEval
    }
}

func findBestMove(game: Game, depth: Int, maximizingPlayer: Bool) -> Move? {
    return iterativeDeepening(game: game, initialDepth: depth, maximizingPlayer: maximizingPlayer)
}

func iterativeDeepening(game: Game, initialDepth: Int, maximizingPlayer: Bool) -> Move? {
    let searchStartTime = Date().timeIntervalSince1970
    var bestMove: Move? = nil
    var bestEval = maximizingPlayer ? Int.min : Int.max

    for depth in initialDepth...100 {
        if isTimeLimitExceeded(searchStartTime: searchStartTime) {
            break
        }
        let (move, eval) = performSearch(game: game, depth: depth, maximizingPlayer: maximizingPlayer)
        if maximizingPlayer {
            if eval > bestEval {
                bestEval = eval
                bestMove = move
            }
        } else {
            if eval < bestEval {
                bestEval = eval
                bestMove = move
            }
        }
    }

    return bestMove
}

func performSearch(game: Game, depth: Int, maximizingPlayer: Bool) -> (Move?, Int) {
    let legalMoves = generateAllLegalMoves(boardState: game.boardState).sorted(by: >)
    
    
    var bestMove: Move? = nil
    var alpha = Int.min
    var beta = Int.max
    var bestEval = maximizingPlayer ? Int.min : Int.max

    if maximizingPlayer {
        for move in legalMoves {
            game.makeMove(move: move)

            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            game.undoMove()

            if eval > bestEval {
                bestEval = eval
                bestMove = move
                alpha = max(alpha, bestEval)
            }

            if beta <= alpha {
                break
            }
        }
    } else {
        for move in legalMoves {
            game.makeMove(move: move)

            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true)
            game.undoMove()

            if eval < bestEval {
                bestEval = eval
                bestMove = move
                beta = min(beta, bestEval)
            }

            if beta <= alpha {
                break
            }
        }
    }

    return (bestMove, bestEval)
}
