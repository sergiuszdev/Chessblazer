//
//  Evaluation.swift
//  Chessblazer
//
//  Created by sergiusz on 06/08/2024.
//

import Foundation

let MATE_VALUE = 50000
private let quiescenceMaxPly = 12

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

final class SearchContext {
    let startTime: TimeInterval
    let timeLimit: TimeInterval?
    let isCancelled: () -> Bool
    let onInfo: ((String) -> Void)?
    private(set) var timedOut = false
    
    init(
        limits: SearchLimits,
        isCancelled: @escaping () -> Bool = { false },
        onInfo: ((String) -> Void)? = nil
    ) {
        startTime = Date().timeIntervalSince1970
        timeLimit = limits.allocatedTime
        self.isCancelled = isCancelled
        self.onInfo = onInfo
    }
    
    func shouldStop() -> Bool {
        if isCancelled() {
            timedOut = true
            return true
        }
        guard let timeLimit else { return false }
        if Date().timeIntervalSince1970 - startTime >= timeLimit {
            timedOut = true
            return true
        }
        return false
    }
}

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

func terminalScore(game: Game, ply: Int) -> Int? {
    guard game.boardState.currentValidMoves.isEmpty else { return nil }
    if checkIfCheck(boardState: game.boardState) {
        if game.boardState.currentTurnColor == .white {
            return -MATE_VALUE + ply
        } else {
            return MATE_VALUE - ply
        }
    }
    return 0
}

func isTactical(_ move: Move) -> Bool {
    if move.castling { return false }
    return move.captureValue != 0 || move.promotionPiece != 0 || move.enPasssantCapture != 0
}

func alphabeta(game: Game, depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool, ply: Int, context: SearchContext) -> Int {
    var alpha = alpha
    var beta = beta
    
    if context.shouldStop() {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    if let score = terminalScore(game: game, ply: ply) {
        return score
    }
    
    if depth <= 0 {
        return quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: maximizingPlayer, ply: ply, qsPly: 0, context: context)
    }
    
    let moves = game.boardState.currentValidMoves.sorted(by: >)
    if maximizingPlayer {
        var maxEval = Int.min
        for move in moves {
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false, ply: ply + 1, context: context)
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
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true, ply: ply + 1, context: context)
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

func quiesce(game: Game, alpha: Int, beta: Int, maximizingPlayer: Bool, ply: Int, qsPly: Int, context: SearchContext) -> Int {
    var alpha = alpha
    var beta = beta
    
    if context.shouldStop() {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    if let score = terminalScore(game: game, ply: ply) {
        return score
    }
    
    let inCheck = checkIfCheck(boardState: game.boardState)
    let standPat = evaluate(bitboards: game.boardState.bitboards)
    
    if !inCheck {
        if maximizingPlayer {
            if standPat >= beta { return standPat }
            alpha = max(alpha, standPat)
        } else {
            if standPat <= alpha { return standPat }
            beta = min(beta, standPat)
        }
        if qsPly >= quiescenceMaxPly {
            return standPat
        }
    } else if qsPly >= quiescenceMaxPly {
        return standPat
    }
    
    let moves = inCheck
        ? game.boardState.currentValidMoves.sorted(by: >)
        : game.boardState.currentValidMoves.filter(isTactical).sorted(by: >)
    
    if moves.isEmpty {
        return standPat
    }
    
    if maximizingPlayer {
        var maxEval = inCheck ? Int.min : standPat
        for move in moves {
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: false, ply: ply + 1, qsPly: qsPly + 1, context: context)
            game.undoMove()
            
            maxEval = max(maxEval, eval)
            alpha = max(alpha, maxEval)
            if beta <= alpha {
                break
            }
        }
        return maxEval
    } else {
        var minEval = inCheck ? Int.max : standPat
        for move in moves {
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: true, ply: ply + 1, qsPly: qsPly + 1, context: context)
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
    return findBestMove(game: game, limits: SearchLimits(maxDepth: depth, allocatedTime: nil), maximizingPlayer: maximizingPlayer)
}

func findBestMove(
    game: Game,
    limits: SearchLimits,
    maximizingPlayer: Bool,
    isCancelled: @escaping () -> Bool = { false },
    onInfo: ((String) -> Void)? = nil
) -> Move? {
    let searched = iterativeDeepening(
        game: game,
        limits: limits,
        maximizingPlayer: maximizingPlayer,
        isCancelled: isCancelled,
        onInfo: onInfo
    )
    return searched ?? game.boardState.currentValidMoves.first
}

func iterativeDeepening(
    game: Game,
    limits: SearchLimits,
    maximizingPlayer: Bool,
    isCancelled: @escaping () -> Bool,
    onInfo: ((String) -> Void)?
) -> Move? {
    let context = SearchContext(limits: limits, isCancelled: isCancelled, onInfo: onInfo)
    var bestMove: Move? = nil
    
    for depth in 1...limits.maxDepth {
        if context.shouldStop() {
            break
        }
        let (move, eval) = performSearch(game: game, depth: depth, maximizingPlayer: maximizingPlayer, context: context)
        if let move {
            bestMove = move
            let engineScore = maximizingPlayer ? eval : -eval
            onInfo?("info depth \(depth) score cp \(engineScore)")
        }
        if context.timedOut {
            break
        }
    }
    
    return bestMove
}

func performSearch(game: Game, depth: Int, maximizingPlayer: Bool, context: SearchContext) -> (Move?, Int) {
    let legalMoves = game.boardState.currentValidMoves.sorted(by: >)
    
    if legalMoves.isEmpty {
        return (nil, terminalScore(game: game, ply: 0) ?? 0)
    }
    
    var bestMove: Move? = nil
    var alpha = -MATE_VALUE * 2
    var beta = MATE_VALUE * 2
    var bestEval = maximizingPlayer ? Int.min : Int.max
    
    if maximizingPlayer {
        for move in legalMoves {
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false, ply: 1, context: context)
            game.undoMove()
            
            if eval > bestEval {
                bestEval = eval
                bestMove = move
                alpha = max(alpha, bestEval)
            }
        }
    } else {
        for move in legalMoves {
            if context.shouldStop() { break }
            game.makeMove(move: move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true, ply: 1, context: context)
            game.undoMove()
            
            if eval < bestEval {
                bestEval = eval
                bestMove = move
                beta = min(beta, bestEval)
            }
        }
    }
    
    return (bestMove, bestEval)
}
