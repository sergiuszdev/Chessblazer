//
//  Evaluation.swift
//  Chessblazer
//
//  Created by sergiusz on 06/08/2024.
//

import Foundation

let MATE_VALUE = 50000
private let quiescenceMaxPly = 12
private let maxSearchPly = 128
private let nullMoveMinDepth = 3
private let nullMoveReduction = 2
private let lmrMinDepth = 3
private let lmrMinMoveIndex = 3

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
    let tt: TranspositionTable
    private(set) var timedOut = false
    private var killers: [(Move?, Move?)]
    private(set) var history: [[Int]]
    
    init(
        limits: SearchLimits,
        isCancelled: @escaping () -> Bool = { false },
        onInfo: ((String) -> Void)? = nil,
        tt: TranspositionTable
    ) {
        startTime = Date().timeIntervalSince1970
        timeLimit = limits.allocatedTime
        self.isCancelled = isCancelled
        self.onInfo = onInfo
        self.tt = tt
        killers = Array(repeating: (nil, nil), count: maxSearchPly)
        history = Array(
            repeating: Array(repeating: 0, count: 64),
            count: PieceBitboards.slotCount
        )
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
    
    func killers(at ply: Int) -> (Move?, Move?) {
        guard (0..<maxSearchPly).contains(ply) else { return (nil, nil) }
        return killers[ply]
    }
    
    func rememberKiller(_ move: Move, ply: Int) {
        guard (0..<maxSearchPly).contains(ply), !isTactical(move) else { return }
        if move == killers[ply].0 { return }
        killers[ply].1 = killers[ply].0
        killers[ply].0 = move
    }
    
    func updateHistory(_ move: Move, delta: Int) {
        guard !isTactical(move), move.pieceValue != 0, let target = move.targetSquare else { return }
        let slot = PieceBitboards.slot(for: move.pieceValue)
        guard (0..<history.count).contains(slot), (0..<64).contains(target) else { return }
        let next = min(max(history[slot][target] + delta, -8_000), 32_000)
        history[slot][target] = next
    }
}

func countMaterial(bitboards: PieceBitboards) -> Int {
    let phase = GamePhase.of(bitboards)
    var whiteSum = 0
    var blackSum = 0
    bitboards.forEachOccupied { piece, bitboard in
        let pieceValue = PieceValueTable[piece] ?? 0
        var bitboardCopy = bitboard
        while bitboardCopy != 0 {
            let position = Bitboard.popLSB(&bitboardCopy)
            let pst = PieceSquareTables.pieceSquareValue(piece: piece, square: position, phase: phase)
            if Piece.checkColor(piece: piece) == .white {
                whiteSum += pieceValue + pst
            } else {
                blackSum += pieceValue - pst
            }
        }
    }
    return whiteSum + blackSum
}

func evaluate(bitboards: PieceBitboards) -> Int {
    return countMaterial(bitboards: bitboards)
}

func terminalScore(game: Game, ply: Int, legalMoves: [Move]? = nil) -> Int? {
    let moves = legalMoves ?? game.boardState.currentValidMoves
    guard moves.isEmpty else { return nil }
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

func hasNonPawnMaterial(bitboards: PieceBitboards, color: Piece.Color) -> Bool {
    if color == .white {
        return bitboards[Piece.ColoredPieces.whiteKnight.rawValue] != 0
            || bitboards[Piece.ColoredPieces.whiteBishop.rawValue] != 0
            || bitboards[Piece.ColoredPieces.whiteRook.rawValue] != 0
            || bitboards[Piece.ColoredPieces.whiteQueen.rawValue] != 0
    }
    return bitboards[Piece.ColoredPieces.blackKnight.rawValue] != 0
        || bitboards[Piece.ColoredPieces.blackBishop.rawValue] != 0
        || bitboards[Piece.ColoredPieces.blackRook.rawValue] != 0
        || bitboards[Piece.ColoredPieces.blackQueen.rawValue] != 0
}

func alphabeta(
    game: Game,
    depth: Int,
    alpha: Int,
    beta: Int,
    maximizingPlayer: Bool,
    ply: Int,
    context: SearchContext,
    canNull: Bool = true
) -> Int {
    var alpha = alpha
    var beta = beta
    
    if context.shouldStop() {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    if depth <= 0 {
        return quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: maximizingPlayer, ply: ply, qsPly: 0, context: context)
    }
    
    let originalAlpha = alpha
    let originalBeta = beta
    let key = game.boardState.zobristKey
    var ttMove: Move? = nil
    
    if let hit = context.tt.probe(key) {
        let score = TranspositionTable.scoreFromTT(hit.score, ply: ply)
        ttMove = hit.move
        if hit.depth >= depth {
            switch hit.bound {
            case .exact:
                return score
            case .lower:
                if score >= beta { return score }
                alpha = max(alpha, score)
            case .upper:
                if score <= alpha { return score }
                beta = min(beta, score)
            case .empty:
                break
            }
            if alpha >= beta {
                return score
            }
        }
    }
    
    let inCheck = checkIfCheck(boardState: game.boardState)
    
    if canNull
        && !inCheck
        && depth >= nullMoveMinDepth
        && hasNonPawnMaterial(bitboards: game.boardState.bitboards, color: game.boardState.currentTurnColor)
    {
        let mateBound = TranspositionTable.mateScoreThreshold
        let lookingForMate = maximizingPlayer ? beta >= mateBound : alpha <= -mateBound
        if !lookingForMate {
            game.playNull()
            let nmpDepth = depth - 1 - nullMoveReduction
            let score = alphabeta(
                game: game,
                depth: nmpDepth,
                alpha: alpha,
                beta: beta,
                maximizingPlayer: !maximizingPlayer,
                ply: ply + 1,
                context: context,
                canNull: false
            )
            game.unplay()
            if context.shouldStop() {
                return score
            }
            let cutoff = maximizingPlayer ? score >= beta : score <= alpha
            if cutoff {
                context.tt.store(
                    key: key,
                    depth: max(1, nmpDepth),
                    score: TranspositionTable.scoreToTT(score, ply: ply),
                    bound: maximizingPlayer ? .lower : .upper,
                    move: nil
                )
                return score
            }
        }
    }
    
    var moves = generateAllLegalMoves(boardState: game.boardState)
    orderMoves(
        &moves,
        ttMove: ttMove,
        killers: context.killers(at: ply),
        history: context.history
    )
    if let score = terminalScore(game: game, ply: ply, legalMoves: moves) {
        context.tt.store(
            key: key,
            depth: depth,
            score: TranspositionTable.scoreToTT(score, ply: ply),
            bound: .exact,
            move: nil
        )
        return score
    }
    
    var bestEval = maximizingPlayer ? Int.min : Int.max
    var bestMove: Move? = nil
    var interrupted = false
    var quietsTried = [Move]()
    
    func searchMove(_ move: Move, index: Int) -> Int {
        game.play(move)
        defer { game.unplay() }
        let fullDepth = depth - 1
        let reduce = !inCheck
            && depth >= lmrMinDepth
            && index >= lmrMinMoveIndex
            && !isTactical(move)
        if reduce {
            let reduction = 1 + index / 8
            let reducedDepth = max(1, fullDepth - reduction)
            var eval = alphabeta(
                game: game,
                depth: reducedDepth,
                alpha: alpha,
                beta: beta,
                maximizingPlayer: !maximizingPlayer,
                ply: ply + 1,
                context: context
            )
            let needsResearch = maximizingPlayer ? eval > alpha : eval < beta
            if needsResearch && !context.shouldStop() {
                eval = alphabeta(
                    game: game,
                    depth: fullDepth,
                    alpha: alpha,
                    beta: beta,
                    maximizingPlayer: !maximizingPlayer,
                    ply: ply + 1,
                    context: context
                )
            }
            return eval
        }
        return alphabeta(
            game: game,
            depth: fullDepth,
            alpha: alpha,
            beta: beta,
            maximizingPlayer: !maximizingPlayer,
            ply: ply + 1,
            context: context
        )
    }
    
    func recordQuietCutoff(_ move: Move) {
        context.rememberKiller(move, ply: ply)
        context.updateHistory(move, delta: depth * depth)
        for quiet in quietsTried {
            context.updateHistory(quiet, delta: -depth)
        }
    }
    
    for (index, move) in moves.enumerated() {
        if context.shouldStop() {
            interrupted = true
            break
        }
        let eval = searchMove(move, index: index)
        
        if maximizingPlayer {
            if eval > bestEval {
                bestEval = eval
                bestMove = move
            }
            alpha = max(alpha, bestEval)
            if beta <= alpha {
                if !isTactical(move) {
                    recordQuietCutoff(move)
                }
                break
            }
        } else {
            if eval < bestEval {
                bestEval = eval
                bestMove = move
            }
            beta = min(beta, bestEval)
            if beta <= alpha {
                if !isTactical(move) {
                    recordQuietCutoff(move)
                }
                break
            }
        }
        
        if !isTactical(move) {
            quietsTried.append(move)
        }
    }
    
    if !interrupted && !context.timedOut {
        let bound: TTBound
        if bestEval <= originalAlpha {
            bound = .upper
        } else if bestEval >= originalBeta {
            bound = .lower
        } else {
            bound = .exact
        }
        context.tt.store(
            key: key,
            depth: depth,
            score: TranspositionTable.scoreToTT(bestEval, ply: ply),
            bound: bound,
            move: bestMove
        )
    }
    
    return bestEval
}

func quiesce(game: Game, alpha: Int, beta: Int, maximizingPlayer: Bool, ply: Int, qsPly: Int, context: SearchContext) -> Int {
    var alpha = alpha
    var beta = beta
    
    if context.shouldStop() {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    let legalMoves = generateAllLegalMoves(boardState: game.boardState)
    if let score = terminalScore(game: game, ply: ply, legalMoves: legalMoves) {
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
        ? legalMoves.sorted(by: >)
        : legalMoves.filter(isTactical).sorted(by: >)
    
    if moves.isEmpty {
        return standPat
    }
    
    if maximizingPlayer {
        var maxEval = inCheck ? Int.min : standPat
        for move in moves {
            if context.shouldStop() { break }
            game.play(move)
            let eval = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: false, ply: ply + 1, qsPly: qsPly + 1, context: context)
            game.unplay()
            
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
            game.play(move)
            let eval = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: true, ply: ply + 1, qsPly: qsPly + 1, context: context)
            game.unplay()
            
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
    onInfo: ((String) -> Void)? = nil,
    tt: TranspositionTable? = nil
) -> Move? {
    let rootMoves = game.boardState.currentValidMoves
    let searched = iterativeDeepening(
        game: game,
        limits: limits,
        maximizingPlayer: maximizingPlayer,
        isCancelled: isCancelled,
        onInfo: onInfo,
        tt: tt ?? TranspositionTable(megabytes: 1)
    )
    if let searched, rootMoves.contains(searched) {
        return searched
    }
    return rootMoves.first
}

func iterativeDeepening(
    game: Game,
    limits: SearchLimits,
    maximizingPlayer: Bool,
    isCancelled: @escaping () -> Bool,
    onInfo: ((String) -> Void)?,
    tt: TranspositionTable
) -> Move? {
    let context = SearchContext(limits: limits, isCancelled: isCancelled, onInfo: onInfo, tt: tt)
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
    var legalMoves = game.boardState.currentValidMoves
    let ttMove = context.tt.probe(game.boardState.zobristKey)?.move
    orderMoves(
        &legalMoves,
        ttMove: ttMove,
        killers: context.killers(at: 0),
        history: context.history
    )
    
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
            game.play(move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false, ply: 1, context: context)
            game.unplay()
            
            if eval > bestEval {
                bestEval = eval
                bestMove = move
                alpha = max(alpha, bestEval)
            }
        }
    } else {
        for move in legalMoves {
            if context.shouldStop() { break }
            game.play(move)
            let eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true, ply: 1, context: context)
            game.unplay()
            
            if eval < bestEval {
                bestEval = eval
                bestMove = move
                beta = min(beta, bestEval)
            }
        }
    }
    
    return (bestMove, bestEval)
}
