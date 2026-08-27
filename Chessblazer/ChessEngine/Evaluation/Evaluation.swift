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
private let rfpMaxDepth = 4
private let rfpMarginPerDepth = 200
private let razorMaxDepth = 2
private let razorMargin = 600
private let futilityMaxDepth = 2
private let futilityMarginPerDepth = 200
private let aspirationMinDepth = 4
private let aspirationWindow = 25
private let aspirationMaxFails = 5
private let searchInfinity = MATE_VALUE * 2

private func addScore(_ score: Int, _ delta: Int) -> Int {
    if delta <= 0 { return score }
    if score > searchInfinity - delta { return searchInfinity }
    return min(searchInfinity, score + delta)
}

private func subtractScore(_ score: Int, _ delta: Int) -> Int {
    if delta <= 0 { return score }
    if score < -searchInfinity + delta { return -searchInfinity }
    return max(-searchInfinity, score - delta)
}

private func pvsProbeWindow(alpha: Int, beta: Int, maximizingPlayer: Bool) -> (Int, Int) {
    if maximizingPlayer {
        return (alpha, addScore(alpha, 1))
    }
    return (subtractScore(beta, 1), beta)
}

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
    private(set) var softLimit: TimeInterval?
    let hardLimit: TimeInterval?
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
        softLimit = limits.allocatedTime
        hardLimit = limits.hardTime ?? limits.allocatedTime
        self.isCancelled = isCancelled
        self.onInfo = onInfo
        self.tt = tt
        killers = Array(repeating: (nil, nil), count: maxSearchPly)
        history = Array(
            repeating: Array(repeating: 0, count: 64),
            count: PieceBitboards.slotCount
        )
    }
    
    var elapsed: TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }
    
    func shouldStop() -> Bool {
        if isCancelled() {
            timedOut = true
            return true
        }
        guard let hardLimit else { return false }
        if elapsed >= hardLimit {
            timedOut = true
            return true
        }
        return false
    }
    
    /// Soft budget used up: do not start another iterative-deepening depth.
    func softTimeExceeded() -> Bool {
        guard let softLimit else { return false }
        return elapsed >= softLimit
    }
    
    /// After a root fail-low, stretch the soft budget toward the hard cap.
    func extendSoftForFailLow() {
        guard let soft = softLimit, let hard = hardLimit else { return }
        softLimit = min(hard, soft + max(soft * 0.5, 0.05))
    }
    
    /// Stable PV and most of the soft budget used: stop early.
    func shouldStopForEasyMove(stableDepths: Int) -> Bool {
        guard stableDepths >= 3, let soft = softLimit else { return false }
        return elapsed >= soft * 0.45
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

func countMaterial(bitboards: PieceBitboards, phase: Int? = nil) -> Int {
    let phase = phase ?? GamePhase.of(bitboards)
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

public func evaluate(bitboards: PieceBitboards) -> Int {
    let occupancy = Occupancy.from(bitboards: bitboards)
    let phase = GamePhase.of(bitboards)
    return countMaterial(bitboards: bitboards, phase: phase)
        + evaluatePawnStructure(bitboards: bitboards, phase: phase)
        + evaluateMobility(bitboards: bitboards, occupancy: occupancy, phase: phase)
        + evaluateKingSafety(bitboards: bitboards, occupancy: occupancy, phase: phase)
}

private enum EvalMasks {
    static let files: [Bitboard] = (0..<8).map { Bitboard.Masks.fileA << $0 }
    static let adjacentFiles: [Bitboard] = (0..<8).map { file in
        var mask: Bitboard = 0
        if file > 0 { mask |= files[file - 1] }
        if file < 7 { mask |= files[file + 1] }
        return mask
    }
    static let whitePassed: [Bitboard] = (0..<64).map { whiteFrontSpan(square: $0) }
    static let blackPassed: [Bitboard] = (0..<64).map { blackFrontSpan(square: $0) }
    static let whiteShield: [Bitboard] = (0..<64).map { kingShield(square: $0, white: true) }
    static let blackShield: [Bitboard] = (0..<64).map { kingShield(square: $0, white: false) }
    
    private static func whiteFrontSpan(square: Int) -> Bitboard {
        let file = square % 8
        let rank = square / 8
        var mask: Bitboard = 0
        guard rank < 7 else { return 0 }
        for nextRank in (rank + 1)...7 {
            for delta in -1...1 {
                let nextFile = file + delta
                if (0..<8).contains(nextFile) {
                    mask |= Bitboard(1) << Bitboard(nextRank * 8 + nextFile)
                }
            }
        }
        return mask
    }
    
    private static func blackFrontSpan(square: Int) -> Bitboard {
        let file = square % 8
        let rank = square / 8
        var mask: Bitboard = 0
        guard rank > 0 else { return 0 }
        for nextRank in 0..<rank {
            for delta in -1...1 {
                let nextFile = file + delta
                if (0..<8).contains(nextFile) {
                    mask |= Bitboard(1) << Bitboard(nextRank * 8 + nextFile)
                }
            }
        }
        return mask
    }
    
    private static func kingShield(square: Int, white: Bool) -> Bitboard {
        let file = square % 8
        let rank = square / 8
        var mask: Bitboard = 0
        let ranks = white ? [rank + 1, rank + 2] : [rank - 1, rank - 2]
        for nextRank in ranks where (0...7).contains(nextRank) {
            for nextFile in (file - 1)...(file + 1) where (0...7).contains(nextFile) {
                mask |= Bitboard(1) << Bitboard(nextRank * 8 + nextFile)
            }
        }
        return mask
    }
}

private let doubledPawnPenalty = 16
private let isolatedPawnPenalty = 12

func evaluatePawnStructure(bitboards: PieceBitboards, phase: Int) -> Int {
    let whitePawns = bitboards[Piece.ColoredPieces.whitePawn.rawValue]
    let blackPawns = bitboards[Piece.ColoredPieces.blackPawn.rawValue]
    let white = pawnStructureScore(pawns: whitePawns, enemy: blackPawns, passedMasks: EvalMasks.whitePassed)
    let black = pawnStructureScore(pawns: blackPawns, enemy: whitePawns, passedMasks: EvalMasks.blackPassed)
    return GamePhase.interpolate(
        middlegame: white.mg - black.mg,
        endgame: white.eg - black.eg,
        phase: phase
    )
}

private func pawnStructureScore(pawns: Bitboard, enemy: Bitboard, passedMasks: [Bitboard]) -> (mg: Int, eg: Int) {
    var mg = 0
    var eg = 0
    var remaining = pawns
    while remaining != 0 {
        let square = Bitboard.popLSB(&remaining)
        let file = square % 8
        if pawns & EvalMasks.adjacentFiles[file] == 0 {
            mg -= isolatedPawnPenalty
            eg -= isolatedPawnPenalty
        }
        if enemy & passedMasks[square] == 0 {
            mg += 18
            eg += 40
        }
    }
    for file in 0..<8 {
        let extra = Int((pawns & EvalMasks.files[file]).nonzeroBitCount) - 1
        if extra > 0 {
            mg -= extra * doubledPawnPenalty
            eg -= extra * doubledPawnPenalty
        }
    }
    return (mg, eg)
}

func evaluateMobility(bitboards: PieceBitboards, occupancy: Occupancy, phase: Int) -> Int {
    let white = mobilityScore(bitboards: bitboards, occupancy: occupancy, color: .white)
    let black = mobilityScore(bitboards: bitboards, occupancy: occupancy, color: .black)
    return GamePhase.interpolate(
        middlegame: white.mg - black.mg,
        endgame: white.eg - black.eg,
        phase: phase
    )
}

private func mobilityScore(bitboards: PieceBitboards, occupancy: Occupancy, color: Piece.Color) -> (mg: Int, eg: Int) {
    let friendly = occupancy.friendly(for: color)
    var mg = 0
    var eg = 0
    
    func add(_ board: Bitboard, mgUnit: Int, egUnit: Int, attacks: (Int) -> Bitboard) {
        var remaining = board
        while remaining != 0 {
            let square = Bitboard.popLSB(&remaining)
            let count = attacks(square).nonzeroBitCount
            mg += mgUnit * count
            eg += egUnit * count
        }
    }
    
    let knight = color == .white ? Piece.ColoredPieces.whiteKnight.rawValue : Piece.ColoredPieces.blackKnight.rawValue
    let bishop = color == .white ? Piece.ColoredPieces.whiteBishop.rawValue : Piece.ColoredPieces.blackBishop.rawValue
    let rook = color == .white ? Piece.ColoredPieces.whiteRook.rawValue : Piece.ColoredPieces.blackRook.rawValue
    let queen = color == .white ? Piece.ColoredPieces.whiteQueen.rawValue : Piece.ColoredPieces.blackQueen.rawValue
    
    add(bitboards[knight], mgUnit: 4, egUnit: 3) { generateKnightAttacks(square: $0, friendlyBitboard: friendly) }
    add(bitboards[bishop], mgUnit: 3, egUnit: 3) { generateBishopAttacks(square: $0, friendlyBitboard: friendly, occupancy: occupancy) }
    add(bitboards[rook], mgUnit: 2, egUnit: 3) { generateRookAttacks(square: $0, friendlyBitboard: friendly, occupancy: occupancy) }
    add(bitboards[queen], mgUnit: 1, egUnit: 1) { generateQueenAttacks(square: $0, friendlyBitboard: friendly, occupancy: occupancy) }
    return (mg, eg)
}

func evaluateKingSafety(bitboards: PieceBitboards, occupancy: Occupancy, phase: Int) -> Int {
    let white = kingSafetyPenalty(bitboards: bitboards, occupancy: occupancy, color: .white)
    let black = kingSafetyPenalty(bitboards: bitboards, occupancy: occupancy, color: .black)
    return GamePhase.interpolate(middlegame: black - white, endgame: 0, phase: phase)
}

private func kingSafetyPenalty(bitboards: PieceBitboards, occupancy: Occupancy, color: Piece.Color) -> Int {
    let kingPiece = color == .white ? Piece.ColoredPieces.whiteKing.rawValue : Piece.ColoredPieces.blackKing.rawValue
    var kingBoard = bitboards[kingPiece]
    guard kingBoard != 0 else { return 0 }
    let kingSquare = Bitboard.popLSB(&kingBoard)
    let kingBB = Bitboard(1) << Bitboard(kingSquare)
    let zone = generateKingAttacks(king: kingBB) | kingBB
    
    let pawns = color == .white
        ? bitboards[Piece.ColoredPieces.whitePawn.rawValue]
        : bitboards[Piece.ColoredPieces.blackPawn.rawValue]
    let shield = color == .white ? EvalMasks.whiteShield[kingSquare] : EvalMasks.blackShield[kingSquare]
    let missingShield = max(0, 3 - Int((pawns & shield).nonzeroBitCount))
    
    let enemy = color.getOppositeColor()
    var attackUnits = 0
    let enemyPawns = enemy == .white
        ? bitboards[Piece.ColoredPieces.whitePawn.rawValue]
        : bitboards[Piece.ColoredPieces.blackPawn.rawValue]
    let pawnAttacks = enemy == .white
        ? generateWhitePawnAttacks(whitePawns: enemyPawns)
        : generateBlackPawnAttacks(blackPawns: enemyPawns)
    attackUnits += (pawnAttacks & zone).nonzeroBitCount
    
    func addAttackers(_ board: Bitboard, weight: Int, attacks: (Int) -> Bitboard) {
        var remaining = board
        while remaining != 0 {
            let square = Bitboard.popLSB(&remaining)
            if attacks(square) & zone != 0 {
                attackUnits += weight
            }
        }
    }
    
    let enemyFriendly = occupancy.friendly(for: enemy)
    let knight = enemy == .white ? Piece.ColoredPieces.whiteKnight.rawValue : Piece.ColoredPieces.blackKnight.rawValue
    let bishop = enemy == .white ? Piece.ColoredPieces.whiteBishop.rawValue : Piece.ColoredPieces.blackBishop.rawValue
    let rook = enemy == .white ? Piece.ColoredPieces.whiteRook.rawValue : Piece.ColoredPieces.blackRook.rawValue
    let queen = enemy == .white ? Piece.ColoredPieces.whiteQueen.rawValue : Piece.ColoredPieces.blackQueen.rawValue
    
    addAttackers(bitboards[knight], weight: 2) { generateKnightAttacks(square: $0, friendlyBitboard: enemyFriendly) }
    addAttackers(bitboards[bishop], weight: 2) { generateBishopAttacks(square: $0, friendlyBitboard: enemyFriendly, occupancy: occupancy) }
    addAttackers(bitboards[rook], weight: 3) { generateRookAttacks(square: $0, friendlyBitboard: enemyFriendly, occupancy: occupancy) }
    addAttackers(bitboards[queen], weight: 5) { generateQueenAttacks(square: $0, friendlyBitboard: enemyFriendly, occupancy: occupancy) }
    
    let capped = min(attackUnits, 12)
    return missingShield * 14 + capped * capped
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

func resetsFiftyMove(_ move: Move) -> Bool {
    if move.castling { return false }
    return Piece.getType(piece: move.pieceValue) == .pawn
        || move.captureValue != 0
        || move.enPasssantCapture != 0
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
    
    if ply >= maxSearchPly {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    if game.boardState.isRepetitionDraw(ply: ply) {
        return 0
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
    let mateBound = TranspositionTable.mateScoreThreshold
    let lookingForMate = maximizingPlayer ? beta >= mateBound : alpha <= -mateBound
    let staticEval = evaluate(bitboards: game.boardState.bitboards)
    
    if !inCheck && !lookingForMate && depth <= rfpMaxDepth {
        let margin = rfpMarginPerDepth * depth
        if maximizingPlayer, staticEval - margin >= beta {
            return staticEval
        }
        if !maximizingPlayer, staticEval + margin <= alpha {
            return staticEval
        }
    }
    
    if !inCheck && !lookingForMate && depth <= razorMaxDepth {
        if maximizingPlayer, staticEval + razorMargin <= alpha {
            let qs = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: true, ply: ply, qsPly: 0, context: context)
            if qs <= alpha { return qs }
        }
        if !maximizingPlayer, staticEval - razorMargin >= beta {
            let qs = quiesce(game: game, alpha: alpha, beta: beta, maximizingPlayer: false, ply: ply, qsPly: 0, context: context)
            if qs >= beta { return qs }
        }
    }
    
    if canNull
        && !inCheck
        && !lookingForMate
        && depth >= nullMoveMinDepth
        && hasNonPawnMaterial(bitboards: game.boardState.bitboards, color: game.boardState.currentTurnColor)
    {
        game.playNull()
        let nmpDepth = depth - 1 - nullMoveReduction
        let score = alphabeta(
            game: game,
            depth: nmpDepth,
            alpha: maximizingPlayer ? subtractScore(beta, 1) : alpha,
            beta: maximizingPlayer ? beta : addScore(alpha, 1),
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
    
    var moves = generateAllLegalMoves(boardState: game.boardState)
    orderMoves(
        &moves,
        ttMove: ttMove,
        killers: context.killers(at: ply),
        history: context.history,
        boardState: game.boardState
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
    if game.boardState.isFiftyMoveDraw(hasLegalMoves: true) {
        return 0
    }
    
    var bestEval = maximizingPlayer ? Int.min : Int.max
    var bestMove: Move? = nil
    var interrupted = false
    var quietsTried = [Move]()
    
    func searchMove(_ move: Move, index: Int, isFirst: Bool) -> Int {
        game.play(move)
        defer { game.unplay() }
        let fullDepth = depth - 1
        if isFirst {
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
        let reduce = !inCheck
            && depth >= lmrMinDepth
            && index >= lmrMinMoveIndex
            && !isTactical(move)
        let reduction = reduce ? 1 + index / 8 : 0
        let probeDepth = reduce ? max(1, fullDepth - reduction) : fullDepth
        let probe = pvsProbeWindow(alpha: alpha, beta: beta, maximizingPlayer: maximizingPlayer)
        var eval = alphabeta(
            game: game,
            depth: probeDepth,
            alpha: probe.0,
            beta: probe.1,
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
        let isFirst = index == 0
        if !inCheck && !lookingForMate && depth <= futilityMaxDepth && !isTactical(move) && !isFirst {
            let margin = futilityMarginPerDepth * depth
            if maximizingPlayer, staticEval + margin <= alpha { continue }
            if !maximizingPlayer, staticEval - margin >= beta { continue }
        }
        let eval = searchMove(move, index: index, isFirst: isFirst)
        
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
    
    if ply >= maxSearchPly {
        return evaluate(bitboards: game.boardState.bitboards)
    }
    
    let legalMoves = generateAllLegalMoves(boardState: game.boardState)
    if let score = terminalScore(game: game, ply: ply, legalMoves: legalMoves) {
        return score
    }
    if game.boardState.isFiftyMoveDraw(hasLegalMoves: true) {
        return 0
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
        : legalMoves.filter { move in
            guard isTactical(move) else { return false }
            return seeScore(
                move: move,
                bitboards: game.boardState.bitboards,
                occupancy: game.boardState.occupancy,
                sideToMove: game.boardState.currentTurnColor
            ) >= 0
        }.sorted(by: >)
    
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

public func findBestMove(game: Game, depth: Int, maximizingPlayer: Bool) -> Move? {
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
    tt.newSearch()
    let context = SearchContext(limits: limits, isCancelled: isCancelled, onInfo: onInfo, tt: tt)
    var bestMove: Move? = nil
    var lastScore = 0
    var stableMoveCount = 0
    
    for depth in 1...limits.maxDepth {
        if context.shouldStop() {
            break
        }
        if depth > 1, context.softTimeExceeded() {
            break
        }
        if depth > 1, context.shouldStopForEasyMove(stableDepths: stableMoveCount) {
            break
        }
        
        var delta = aspirationWindow
        var alpha = -searchInfinity
        var beta = searchInfinity
        if depth >= aspirationMinDepth {
            alpha = subtractScore(lastScore, delta)
            beta = addScore(lastScore, delta)
        }
        
        var move: Move?
        var eval = 0
        var fails = 0
        while true {
            (move, eval) = performSearch(
                game: game,
                depth: depth,
                maximizingPlayer: maximizingPlayer,
                context: context,
                alpha: alpha,
                beta: beta
            )
            if context.timedOut || context.shouldStop() {
                break
            }
            if eval > alpha && eval < beta {
                break
            }
            fails += 1
            if eval <= alpha {
                context.extendSoftForFailLow()
            }
            if fails >= aspirationMaxFails {
                if alpha <= -searchInfinity && beta >= searchInfinity {
                    break
                }
                alpha = -searchInfinity
                beta = searchInfinity
                continue
            }
            if eval <= alpha {
                alpha = subtractScore(eval, delta)
                delta = min(delta * 2, searchInfinity)
            } else {
                beta = addScore(eval, delta)
                delta = min(delta * 2, searchInfinity)
            }
        }
        
        if let move, !context.timedOut {
            if let previous = bestMove,
               previous.fromSquare == move.fromSquare,
               previous.targetSquare == move.targetSquare,
               previous.promotionPiece == move.promotionPiece {
                stableMoveCount += 1
            } else {
                stableMoveCount = 1
            }
            bestMove = move
            lastScore = eval
            let engineScore = maximizingPlayer ? eval : -eval
            onInfo?("info depth \(depth) score cp \(engineScore)")
        }
        if context.timedOut {
            break
        }
    }
    
    return bestMove
}

func performSearch(game: Game, depth: Int, maximizingPlayer: Bool, context: SearchContext, alpha: Int, beta: Int) -> (Move?, Int) {
    var legalMoves = game.boardState.currentValidMoves
    let ttMove = context.tt.probe(game.boardState.zobristKey)?.move
    orderMoves(
        &legalMoves,
        ttMove: ttMove,
        killers: context.killers(at: 0),
        history: context.history,
        boardState: game.boardState
    )
    
    if legalMoves.isEmpty {
        return (nil, terminalScore(game: game, ply: 0) ?? 0)
    }
    if game.boardState.isFiftyMoveDraw(hasLegalMoves: true) {
        return (legalMoves.first, 0)
    }
    
    var bestMove: Move? = legalMoves.first
    var alpha = alpha
    var beta = beta
    var bestEval = maximizingPlayer ? Int.min : Int.max
    var searchedAny = false
    
    if maximizingPlayer {
        for (index, move) in legalMoves.enumerated() {
            if context.shouldStop() { break }
            game.play(move)
            let eval: Int
            if index == 0 {
                eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false, ply: 1, context: context)
            } else {
                let window = pvsProbeWindow(alpha: alpha, beta: beta, maximizingPlayer: true)
                var probe = alphabeta(game: game, depth: depth - 1, alpha: window.0, beta: window.1, maximizingPlayer: false, ply: 1, context: context)
                if probe > alpha && probe < beta && !context.shouldStop() {
                    probe = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false, ply: 1, context: context)
                }
                eval = probe
            }
            game.unplay()
            searchedAny = true
            
            if eval > bestEval {
                bestEval = eval
                bestMove = move
                alpha = max(alpha, bestEval)
            }
            if bestEval >= beta {
                break
            }
        }
    } else {
        for (index, move) in legalMoves.enumerated() {
            if context.shouldStop() { break }
            game.play(move)
            let eval: Int
            if index == 0 {
                eval = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true, ply: 1, context: context)
            } else {
                let window = pvsProbeWindow(alpha: alpha, beta: beta, maximizingPlayer: false)
                var probe = alphabeta(game: game, depth: depth - 1, alpha: window.0, beta: window.1, maximizingPlayer: true, ply: 1, context: context)
                if probe < beta && probe > alpha && !context.shouldStop() {
                    probe = alphabeta(game: game, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true, ply: 1, context: context)
                }
                eval = probe
            }
            game.unplay()
            searchedAny = true
            
            if eval < bestEval {
                bestEval = eval
                bestMove = move
                beta = min(beta, bestEval)
            }
            if bestEval <= alpha {
                break
            }
        }
    }
    
    if !searchedAny {
        return (bestMove, 0)
    }
    return (bestMove, bestEval)
}
