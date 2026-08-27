//
//  TranspositionTable.swift
//  Chessblazer
//

import Foundation

enum TTBound: UInt8 {
    case empty = 0
    /// True value is exactly `score`.
    case exact = 1
    /// True value is at least `score` (fail high).
    case lower = 2
    /// True value is at most `score` (fail low).
    case upper = 3
}

struct TTHit {
    let score: Int
    let depth: Int
    let bound: TTBound
    let move: Move?
}

/// In-memory hash table indexed by Zobrist key. Not a database: search probes this every node.
final class TranspositionTable {
    static let mateScoreThreshold = MATE_VALUE - 10_000
    
    private var entries: [TTEntry]
    private var mask: UInt64
    private var generation: UInt8 = 1
    
    init(megabytes: Int) {
        entries = []
        mask = 0
        resize(megabytes: megabytes)
    }
    
    init(entryCount: Int) {
        let count = Self.floorPowerOfTwo(max(entryCount, 1))
        entries = Array(repeating: TTEntry(), count: count)
        mask = UInt64(count - 1)
    }
    
    var capacity: Int { entries.count }
    
    func resize(megabytes: Int) {
        let mb = min(max(megabytes, 1), 4096)
        let bytes = mb * 1024 * 1024
        let count = Self.floorPowerOfTwo(max(bytes / MemoryLayout<TTEntry>.stride, 1))
        if count == entries.count { return }
        entries = Array(repeating: TTEntry(), count: count)
        mask = UInt64(count - 1)
        generation = 1
    }
    
    func clear() {
        entries = Array(repeating: TTEntry(), count: entries.count)
        generation = 1
    }
    
    /// Bump age so stale entries from earlier searches are preferred for replacement.
    func newSearch() {
        generation &+= 1
        if generation == 0 { generation = 1 }
    }
    
    func probe(_ key: UInt64) -> TTHit? {
        let index = Int(key & mask)
        let entry = entries[index]
        guard entry.bound != .empty, entry.key == key else { return nil }
        return TTHit(
            score: Int(entry.score),
            depth: Int(entry.depth),
            bound: entry.bound,
            move: entry.move
        )
    }
    
    func store(key: UInt64, depth: Int, score: Int, bound: TTBound, move: Move?) {
        guard bound != .empty else { return }
        guard score != Int.min, score != Int.max else { return }
        let index = Int(key & mask)
        let current = entries[index]
        if !shouldReplace(current, key: key, depth: depth) {
            return
        }
        let keepMove = current.key == key && move == nil ? current.move : move
        entries[index] = TTEntry(
            key: key,
            score: Int32(clamping: score),
            depth: Int8(clamping: depth),
            bound: bound,
            age: generation,
            from: UInt8(clamping: keepMove?.fromSquare ?? 0),
            to: UInt8(clamping: keepMove?.targetSquare ?? 0),
            promotionPiece: UInt8(clamping: keepMove?.promotionPiece ?? 0),
            hasMove: keepMove?.fromSquare != nil && keepMove?.targetSquare != nil
        )
    }
    
    private func shouldReplace(_ entry: TTEntry, key: UInt64, depth: Int) -> Bool {
        if entry.bound == .empty { return true }
        if entry.key == key { return true }
        if entry.age != generation { return true }
        return depth >= Int(entry.depth)
    }
    
    static func scoreToTT(_ score: Int, ply: Int) -> Int {
        let ply = max(ply, 0)
        if score > Int.max - ply || score < Int.min + ply { return score }
        if score >= mateScoreThreshold { return score + ply }
        if score <= -mateScoreThreshold { return score - ply }
        return score
    }
    
    static func scoreFromTT(_ score: Int, ply: Int) -> Int {
        let ply = max(ply, 0)
        if score > Int.max - ply || score < Int.min + ply { return score }
        if score >= mateScoreThreshold { return score - ply }
        if score <= -mateScoreThreshold { return score + ply }
        return score
    }
    
    private static func floorPowerOfTwo(_ value: Int) -> Int {
        guard value > 1 else { return 1 }
        return 1 << (Int.bitWidth - value.leadingZeroBitCount - 1)
    }
}

private struct TTEntry {
    var key: UInt64 = 0
    var score: Int32 = 0
    var depth: Int8 = 0
    var bound: TTBound = .empty
    var age: UInt8 = 0
    var from: UInt8 = 0
    var to: UInt8 = 0
    var promotionPiece: UInt8 = 0
    var hasMove: Bool = false
    
    var move: Move? {
        guard hasMove else { return nil }
        return Move(
            fromSquare: Int(from),
            targetSquare: Int(to),
            pieceValue: 0,
            captureValue: 0,
            promotionPiece: Int(promotionPiece)
        )
    }
}

func orderMoves(
    _ moves: inout [Move],
    ttMove: Move?,
    killers: (Move?, Move?) = (nil, nil),
    history: [[Int]]? = nil,
    boardState: BoardState? = nil
) {
    moves.sort { lhs, rhs in
        moveOrderScore(lhs, ttMove: ttMove, killers: killers, history: history, boardState: boardState)
            > moveOrderScore(rhs, ttMove: ttMove, killers: killers, history: history, boardState: boardState)
    }
}

private func isSameMove(_ lhs: Move, _ rhs: Move?) -> Bool {
    guard let rhs, let from = rhs.fromSquare, let to = rhs.targetSquare else { return false }
    return lhs.fromSquare == from
        && lhs.targetSquare == to
        && (rhs.promotionPiece == 0 || lhs.promotionPiece == rhs.promotionPiece)
}

private func moveOrderScore(
    _ move: Move,
    ttMove: Move?,
    killers: (Move?, Move?),
    history: [[Int]]?,
    boardState: BoardState?
) -> Int {
    if isSameMove(move, ttMove) { return 1_000_000 }
    if isTactical(move) {
        var score = 500_000 + move.moveValue()
        if let boardState {
            score += seeScore(
                move: move,
                bitboards: boardState.bitboards,
                occupancy: boardState.occupancy,
                sideToMove: boardState.currentTurnColor
            )
        }
        return score
    }
    if isSameMove(move, killers.0) { return 400_000 }
    if isSameMove(move, killers.1) { return 300_000 }
    guard let history, let target = move.targetSquare, move.pieceValue != 0 else { return 0 }
    let slot = PieceBitboards.slot(for: move.pieceValue)
    guard (0..<history.count).contains(slot), (0..<64).contains(target) else { return 0 }
    return history[slot][target]
}
