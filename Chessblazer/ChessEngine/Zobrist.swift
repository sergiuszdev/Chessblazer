//
//  Zobrist.swift
//  Chessblazer
//

import Foundation

/// Random 64-bit keys for pieces, side to move, castling rights, and en passant file.
/// XOR is its own inverse: apply a move by xoring keys in, take it back by xoring the same keys again.
enum Zobrist {
    private static let tables = Tables()
    
    private static let castleOrder: [Character] = ["K", "Q", "k", "q"]
    
    static func pieceKey(piece: Int, square: Int) -> UInt64 {
        tables.pieceKeys[PieceBitboards.slot(for: piece)][square]
    }
    
    static func castleKey(_ rights: Set<Character>) -> UInt64 {
        var key: UInt64 = 0
        for (index, letter) in castleOrder.enumerated() where rights.contains(letter) {
            key ^= tables.castleKeys[index]
        }
        return key
    }
    
    static func enPassantKey(_ file: Int?) -> UInt64 {
        guard let file, (0..<8).contains(file) else { return 0 }
        return tables.enPassantFileKeys[file]
    }
    
    static var blackToMove: UInt64 { tables.blackToMove }
    
    static func compute(_ board: BoardState) -> UInt64 {
        var key: UInt64 = 0
        board.bitboards.forEachOccupied { piece, bitboard in
            var copy = bitboard
            while copy != 0 {
                let square = Bitboard.popLSB(&copy)
                key ^= pieceKey(piece: piece, square: square)
            }
        }
        if board.currentTurnColor == .black {
            key ^= blackToMove
        }
        key ^= castleKey(board.castlesAvailable)
        key ^= enPassantKey(board.enPassantHashFile())
        return key
    }
    
    private struct Tables {
        let pieceKeys: [[UInt64]]
        let castleKeys: [UInt64]
        let enPassantFileKeys: [UInt64]
        let blackToMove: UInt64
        
        init() {
            var rng = SplitMix64(seed: 0xC0FFEE00C4E55B1A)
            pieceKeys = (0..<PieceBitboards.slotCount).map { _ in
                (0..<64).map { _ in rng.next() }
            }
            castleKeys = (0..<4).map { _ in rng.next() }
            enPassantFileKeys = (0..<8).map { _ in rng.next() }
            blackToMove = rng.next()
        }
    }
}

private struct SplitMix64 {
    var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
