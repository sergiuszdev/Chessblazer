//
//  Syzygy.swift
//  Chessblazer
//
//  Wraps Fathom (Ronald de Man / basil00 / Jon Dart) for Syzygy WDL + DTZ probes.
//

import Foundation
#if canImport(Fathom)
import Fathom
#endif

// Fathom result layout (macros from tbprobe.h are not imported into Swift).
private let TB_RESULT_FAILED: UInt32 = 0xFFFF_FFFF
private let TB_RESULT_WDL_MASK: UInt32 = 0x0000_000F
private let TB_RESULT_TO_MASK: UInt32 = 0x0000_03F0
private let TB_RESULT_FROM_MASK: UInt32 = 0x0000_FC00
private let TB_RESULT_PROMOTES_MASK: UInt32 = 0x0007_0000
private let TB_RESULT_EP_MASK: UInt32 = 0x0008_0000
private let TB_RESULT_WDL_SHIFT: UInt32 = 0
private let TB_RESULT_TO_SHIFT: UInt32 = 4
private let TB_RESULT_FROM_SHIFT: UInt32 = 10
private let TB_RESULT_PROMOTES_SHIFT: UInt32 = 16
private let TB_RESULT_EP_SHIFT: UInt32 = 19
private let TB_RESULT_CHECKMATE: UInt32 = 4 // TB_SET_WDL(0, TB_WIN)
private let TB_RESULT_STALEMATE: UInt32 = 2 // TB_SET_WDL(0, TB_DRAW)
private let TB_PROMOTES_QUEEN = 1
private let TB_PROMOTES_ROOK = 2
private let TB_PROMOTES_BISHOP = 3
private let TB_PROMOTES_KNIGHT = 4

enum SyzygyWDL: Int {
    case loss = 0
    case blessedLoss = 1
    case draw = 2
    case cursedWin = 3
    case win = 4
}

/// Syzygy tablebase access via `SyzygyPath`. Init and probes are serialized.
enum Syzygy {
    /// Below mate, above normal eval — used for WDL cutoffs in search.
    static let tablebaseWin = MATE_VALUE - 8_000
    
    private static let lock = NSLock()
    /// Serializes Fathom probes (built with TB_NO_THREADS for Xcode/SPM).
    private static let probeLock = NSLock()
    private static var configuredPath = ""
    private static var largestPieces = 0
    
    static var maxPieces: Int {
        lock.lock()
        defer { lock.unlock() }
        return largestPieces
    }
    
    static var isReady: Bool {
        lock.lock()
        defer { lock.unlock() }
        return largestPieces > 0
    }
    
    static func setPath(_ path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        lock.lock()
        defer { lock.unlock() }
        if trimmed == configuredPath { return }
        configuredPath = trimmed
        if trimmed.isEmpty {
            chessblazer_tb_free()
            largestPieces = 0
            return
        }
        if chessblazer_tb_init(trimmed) {
            largestPieces = Int(chessblazer_tb_largest())
        } else {
            largestPieces = 0
        }
    }
    
    static func pieceCount(bitboards: PieceBitboards) -> Int {
        Int(bitboards.occupancy().all.nonzeroBitCount)
    }
    
    /// WDL probe for search. Requires empty castling rights and a zero halfmove clock
    /// (Fathom's WDL API). Cursed/blessed outcomes are treated as draws (50-move aware).
    static func probeWDL(_ board: BoardState) -> SyzygyWDL? {
        let largest = maxPieces
        guard largest > 0 else { return nil }
        guard board.castlesAvailable.isEmpty else { return nil }
        guard board.halfmoveClock == 0 else { return nil }
        guard pieceCount(bitboards: board.bitboards) <= largest else { return nil }
        
        let bb = bitboards(for: board)
        probeLock.lock()
        let result = chessblazer_tb_probe_wdl(
            bb.white, bb.black, bb.kings, bb.queens, bb.rooks, bb.bishops, bb.knights, bb.pawns,
            0,
            0,
            UInt32(bb.ep),
            board.currentTurnColor == .white
        )
        probeLock.unlock()
        guard result != TB_RESULT_FAILED else { return nil }
        return SyzygyWDL(rawValue: Int(result))
    }
    
    /// White-relative score for a WDL hit.
    static func score(wdl: SyzygyWDL, whiteToMove: Bool, ply: Int) -> Int {
        let stm: Int
        switch wdl {
        case .win:
            stm = tablebaseWin - ply
        case .loss:
            stm = -(tablebaseWin - ply)
        case .draw, .cursedWin, .blessedLoss:
            stm = 0
        }
        return whiteToMove ? stm : -stm
    }
    
    /// Root DTZ probe: returns a legal move that preserves the WDL value, or nil.
    static func probeRootMove(_ board: BoardState) -> Move? {
        let largest = maxPieces
        guard largest > 0 else { return nil }
        guard board.castlesAvailable.isEmpty else { return nil }
        guard pieceCount(bitboards: board.bitboards) <= largest else { return nil }
        
        let bb = bitboards(for: board)
        probeLock.lock()
        let result = chessblazer_tb_probe_root(
            bb.white, bb.black, bb.kings, bb.queens, bb.rooks, bb.bishops, bb.knights, bb.pawns,
            UInt32(min(max(board.halfmoveClock, 0), 100)),
            0,
            UInt32(bb.ep),
            board.currentTurnColor == .white,
            nil
        )
        probeLock.unlock()
        if result == TB_RESULT_FAILED || result == TB_RESULT_CHECKMATE || result == TB_RESULT_STALEMATE {
            return nil
        }
        
        let from = Int((result & TB_RESULT_FROM_MASK) >> TB_RESULT_FROM_SHIFT)
        let to = Int((result & TB_RESULT_TO_MASK) >> TB_RESULT_TO_SHIFT)
        let promotes = Int((result & TB_RESULT_PROMOTES_MASK) >> TB_RESULT_PROMOTES_SHIFT)
        let isEp = ((result & TB_RESULT_EP_MASK) >> TB_RESULT_EP_SHIFT) != 0
        
        return board.currentValidMoves.first { move in
            guard move.fromSquare == from, move.targetSquare == to else { return false }
            if isEp {
                return move.enPasssantCapture != 0
            }
            if promotes == 0 {
                return move.promotionPiece == 0
            }
            return promotionMatches(move.promotionPiece, tbPromotes: promotes)
        }
    }
    
    private struct Bitboards {
        var white: UInt64
        var black: UInt64
        var kings: UInt64
        var queens: UInt64
        var rooks: UInt64
        var bishops: UInt64
        var knights: UInt64
        var pawns: UInt64
        var ep: Int
    }
    
    private static func bitboards(for board: BoardState) -> Bitboards {
        let b = board.bitboards
        let whiteKing = b[Piece.ColoredPieces.whiteKing.rawValue]
        let blackKing = b[Piece.ColoredPieces.blackKing.rawValue]
        let whiteQueen = b[Piece.ColoredPieces.whiteQueen.rawValue]
        let blackQueen = b[Piece.ColoredPieces.blackQueen.rawValue]
        let whiteRook = b[Piece.ColoredPieces.whiteRook.rawValue]
        let blackRook = b[Piece.ColoredPieces.blackRook.rawValue]
        let whiteBishop = b[Piece.ColoredPieces.whiteBishop.rawValue]
        let blackBishop = b[Piece.ColoredPieces.blackBishop.rawValue]
        let whiteKnight = b[Piece.ColoredPieces.whiteKnight.rawValue]
        let blackKnight = b[Piece.ColoredPieces.blackKnight.rawValue]
        let whitePawn = b[Piece.ColoredPieces.whitePawn.rawValue]
        let blackPawn = b[Piece.ColoredPieces.blackPawn.rawValue]
        
        var ep = 0
        if board.enPassant != "-", let square = translateFromNotationToSquare(board.enPassant) {
            ep = square
        }
        
        return Bitboards(
            white: whiteKing | whiteQueen | whiteRook | whiteBishop | whiteKnight | whitePawn,
            black: blackKing | blackQueen | blackRook | blackBishop | blackKnight | blackPawn,
            kings: whiteKing | blackKing,
            queens: whiteQueen | blackQueen,
            rooks: whiteRook | blackRook,
            bishops: whiteBishop | blackBishop,
            knights: whiteKnight | blackKnight,
            pawns: whitePawn | blackPawn,
            ep: ep
        )
    }
    
    private static func promotionMatches(_ piece: Int, tbPromotes: Int) -> Bool {
        let type = Piece.getType(piece: piece)
        switch tbPromotes {
        case TB_PROMOTES_QUEEN: return type == .queen
        case TB_PROMOTES_ROOK: return type == .rook
        case TB_PROMOTES_BISHOP: return type == .bishop
        case TB_PROMOTES_KNIGHT: return type == .knight
        default: return false
        }
    }
}
