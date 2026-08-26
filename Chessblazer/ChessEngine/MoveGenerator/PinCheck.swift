//
//  PinCheck.swift
//  Chessblazer
//

import Foundation

enum Rays {
    /// Squares strictly between `a` and `b`, or 0 if they are not on a rank, file, or diagonal.
    static let between: [[Bitboard]] = {
        var table = Array(repeating: Array(repeating: Bitboard(0), count: 64), count: 64)
        for a in 0..<64 {
            for b in 0..<64 where a != b {
                table[a][b] = squaresBetween(a, b)
            }
        }
        return table
    }()
    
    private static func squaresBetween(_ a: Int, _ b: Int) -> Bitboard {
        let fileA = a % 8
        let rankA = a / 8
        let fileB = b % 8
        let rankB = b / 8
        let df = fileB - fileA
        let dr = rankB - rankA
        if df != 0 && dr != 0 && abs(df) != abs(dr) {
            return 0
        }
        let stepFile = df == 0 ? 0 : df / abs(df)
        let stepRank = dr == 0 ? 0 : dr / abs(dr)
        var mask: Bitboard = 0
        var file = fileA + stepFile
        var rank = rankA + stepRank
        while file != fileB || rank != rankB {
            mask |= Bitboard(1) << Bitboard(rank * 8 + file)
            file += stepFile
            rank += stepRank
        }
        return mask
    }
}

struct PinCheckInfo {
    let kingSquare: Int
    let checkers: Bitboard
    let checkerCount: Int
    let checkMask: Bitboard
    let pinned: Bitboard
    let pinRay: [Bitboard]
    let unsafe: Bitboard
    
    var inCheck: Bool { checkerCount != 0 }
    var doubleCheck: Bool { checkerCount >= 2 }
    
    func allowsNonKingMove(from: Int, to: Int, capturedEP: Int) -> Bool {
        let fromBB = Bitboard(1) << Bitboard(from)
        let dest = Bitboard(1) << Bitboard(to)
        if pinned & fromBB != 0 && pinRay[from] & dest == 0 {
            return false
        }
        var targets = dest
        if capturedEP != 0 {
            targets |= Bitboard(1) << Bitboard(capturedEP)
        }
        return targets & checkMask != 0
    }
    
    static func compute(boardState: BoardState) -> PinCheckInfo? {
        let color = boardState.currentTurnColor
        var kingBoard = getKingBitboard(bitboards: boardState.bitboards, color: color)
        guard kingBoard != 0 else { return nil }
        let kingSquare = Bitboard.popLSB(&kingBoard)
        let occupancy = boardState.occupancy
        let bitboards = boardState.bitboards
        let friendly = occupancy.friendly(for: color)
        let enemy = color.getOppositeColor()
        
        let checkers = attackersTo(
            square: kingSquare,
            attacker: enemy,
            bitboards: bitboards,
            occupancy: occupancy
        )
        let checkerCount = checkers.nonzeroBitCount
        
        var checkMask = ~Bitboard(0)
        if checkerCount == 1 {
            var remaining = checkers
            let checkerSquare = Bitboard.popLSB(&remaining)
            checkMask = Rays.between[kingSquare][checkerSquare] | (Bitboard(1) << Bitboard(checkerSquare))
        } else if checkerCount >= 2 {
            checkMask = 0
        }
        
        var pinned: Bitboard = 0
        var pinRay = Array(repeating: Bitboard(0), count: 64)
        let enemyBishopsQueens =
            bitboards[enemy == .white ? Piece.ColoredPieces.whiteBishop.rawValue : Piece.ColoredPieces.blackBishop.rawValue]
            | bitboards[enemy == .white ? Piece.ColoredPieces.whiteQueen.rawValue : Piece.ColoredPieces.blackQueen.rawValue]
        let enemyRooksQueens =
            bitboards[enemy == .white ? Piece.ColoredPieces.whiteRook.rawValue : Piece.ColoredPieces.blackRook.rawValue]
            | bitboards[enemy == .white ? Piece.ColoredPieces.whiteQueen.rawValue : Piece.ColoredPieces.blackQueen.rawValue]
        var snipers =
            (rawBishopAttacks(square: kingSquare, occupancy: 0) & enemyBishopsQueens)
            | (rawRookAttacks(square: kingSquare, occupancy: 0) & enemyRooksQueens)
        while snipers != 0 {
            let sniper = Bitboard.popLSB(&snipers)
            let between = Rays.between[kingSquare][sniper]
            let blockers = between & occupancy.all
            if blockers.nonzeroBitCount == 1 && blockers & friendly != 0 {
                let square = blockers.trailingZeroBitCount
                pinned |= blockers
                pinRay[square] = between | (Bitboard(1) << Bitboard(sniper))
            }
        }
        
        var kingless = occupancy
        let kingBB = Bitboard(1) << Bitboard(kingSquare)
        if color == .white {
            kingless.white &= ~kingBB
        } else {
            kingless.black &= ~kingBB
        }
        let unsafe = generateRawAttackMap(
            bitboards: bitboards,
            attackerColor: enemy,
            occupancy: kingless
        )
        
        return PinCheckInfo(
            kingSquare: kingSquare,
            checkers: checkers,
            checkerCount: checkerCount,
            checkMask: checkMask,
            pinned: pinned,
            pinRay: pinRay,
            unsafe: unsafe
        )
    }
}

func generateRawAttackMap(bitboards: PieceBitboards, attackerColor: Piece.Color, occupancy: Occupancy) -> Bitboard {
    var attacks: Bitboard = 0
    let occ = occupancy.all
    
    if attackerColor == .white {
        attacks |= generateWhitePawnAttacks(whitePawns: bitboards[Piece.ColoredPieces.whitePawn.rawValue])
        attacks |= generateKingAttacks(king: bitboards[Piece.ColoredPieces.whiteKing.rawValue])
        var knights = bitboards[Piece.ColoredPieces.whiteKnight.rawValue]
        while knights != 0 {
            let square = Bitboard.popLSB(&knights)
            attacks |= generateKnightAttacks(bitboard: Bitboard(1) << Bitboard(square))
        }
        var bishops = bitboards[Piece.ColoredPieces.whiteBishop.rawValue]
        while bishops != 0 {
            attacks |= rawBishopAttacks(square: Bitboard.popLSB(&bishops), occupancy: occ)
        }
        var rooks = bitboards[Piece.ColoredPieces.whiteRook.rawValue]
        while rooks != 0 {
            attacks |= rawRookAttacks(square: Bitboard.popLSB(&rooks), occupancy: occ)
        }
        var queens = bitboards[Piece.ColoredPieces.whiteQueen.rawValue]
        while queens != 0 {
            let square = Bitboard.popLSB(&queens)
            attacks |= rawBishopAttacks(square: square, occupancy: occ)
            attacks |= rawRookAttacks(square: square, occupancy: occ)
        }
    } else {
        attacks |= generateBlackPawnAttacks(blackPawns: bitboards[Piece.ColoredPieces.blackPawn.rawValue])
        attacks |= generateKingAttacks(king: bitboards[Piece.ColoredPieces.blackKing.rawValue])
        var knights = bitboards[Piece.ColoredPieces.blackKnight.rawValue]
        while knights != 0 {
            let square = Bitboard.popLSB(&knights)
            attacks |= generateKnightAttacks(bitboard: Bitboard(1) << Bitboard(square))
        }
        var bishops = bitboards[Piece.ColoredPieces.blackBishop.rawValue]
        while bishops != 0 {
            attacks |= rawBishopAttacks(square: Bitboard.popLSB(&bishops), occupancy: occ)
        }
        var rooks = bitboards[Piece.ColoredPieces.blackRook.rawValue]
        while rooks != 0 {
            attacks |= rawRookAttacks(square: Bitboard.popLSB(&rooks), occupancy: occ)
        }
        var queens = bitboards[Piece.ColoredPieces.blackQueen.rawValue]
        while queens != 0 {
            let square = Bitboard.popLSB(&queens)
            attacks |= rawBishopAttacks(square: square, occupancy: occ)
            attacks |= rawRookAttacks(square: square, occupancy: occ)
        }
    }
    return attacks
}

func attackersTo(square: Int, attacker: Piece.Color, bitboards: PieceBitboards, occupancy: Occupancy) -> Bitboard {
    var attackers: Bitboard = 0
    let occ = occupancy.all
    if attacker == .white {
        attackers |= generateBlackPawnAttacks(square: square) & bitboards[Piece.ColoredPieces.whitePawn.rawValue]
        attackers |= generateKnightAttacks(bitboard: Bitboard(1) << Bitboard(square))
            & bitboards[Piece.ColoredPieces.whiteKnight.rawValue]
        attackers |= generateKingAttacks(king: Bitboard(1) << Bitboard(square))
            & bitboards[Piece.ColoredPieces.whiteKing.rawValue]
        attackers |= rawBishopAttacks(square: square, occupancy: occ)
            & (bitboards[Piece.ColoredPieces.whiteBishop.rawValue] | bitboards[Piece.ColoredPieces.whiteQueen.rawValue])
        attackers |= rawRookAttacks(square: square, occupancy: occ)
            & (bitboards[Piece.ColoredPieces.whiteRook.rawValue] | bitboards[Piece.ColoredPieces.whiteQueen.rawValue])
    } else {
        attackers |= generateWhitePawnAttacks(square: square) & bitboards[Piece.ColoredPieces.blackPawn.rawValue]
        attackers |= generateKnightAttacks(bitboard: Bitboard(1) << Bitboard(square))
            & bitboards[Piece.ColoredPieces.blackKnight.rawValue]
        attackers |= generateKingAttacks(king: Bitboard(1) << Bitboard(square))
            & bitboards[Piece.ColoredPieces.blackKing.rawValue]
        attackers |= rawBishopAttacks(square: square, occupancy: occ)
            & (bitboards[Piece.ColoredPieces.blackBishop.rawValue] | bitboards[Piece.ColoredPieces.blackQueen.rawValue])
        attackers |= rawRookAttacks(square: square, occupancy: occ)
            & (bitboards[Piece.ColoredPieces.blackRook.rawValue] | bitboards[Piece.ColoredPieces.blackQueen.rawValue])
    }
    return attackers
}

func isKingAttacked(bitboards: PieceBitboards, color: Piece.Color, occupancy: Occupancy) -> Bool {
    var kingBoard = getKingBitboard(bitboards: bitboards, color: color)
    guard kingBoard != 0 else { return false }
    let square = Bitboard.popLSB(&kingBoard)
    return attackersTo(square: square, attacker: color.getOppositeColor(), bitboards: bitboards, occupancy: occupancy) != 0
}

func isEnPassantLegal(bitboards: PieceBitboards, color: Piece.Color, move: Move) -> Bool {
    guard let from = move.fromSquare, let target = move.targetSquare, move.enPasssantCapture != 0 else {
        return false
    }
    var boards = bitboards
    boards.movePiece(move.pieceValue, from: from, to: target)
    boards.removePiece(move.captureValue, at: move.enPasssantCapture)
    return !isKingAttacked(bitboards: boards, color: color, occupancy: boards.occupancy())
}
