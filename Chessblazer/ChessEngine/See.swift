//
//  See.swift
//  Chessblazer
//
//  Static exchange evaluation: material left after a capture sequence on one square.
//

import Foundation

func seeScore(move: Move, bitboards: PieceBitboards, occupancy: Occupancy, sideToMove: Piece.Color) -> Int {
    guard let from = move.fromSquare, let to = move.targetSquare else { return 0 }
    guard (0..<64).contains(from), (0..<64).contains(to) else { return 0 }
    if move.castling { return 0 }
    
    let isCapture = move.captureValue != 0 || move.enPasssantCapture != 0
    let isPromo = move.promotionPiece != 0
    if !isCapture && !isPromo { return 0 }
    
    var occ = occupancy.all
    var gain = [Int](repeating: 0, count: 32)
    var depth = 0
    var stm = sideToMove
    
    var capturedValue = seePieceValue(move.captureValue)
    if move.enPasssantCapture != 0 {
        capturedValue = seePieceValue(move.captureValue)
        occ ^= Bitboard.bit(at: move.enPasssantCapture)
    }
    
    gain[0] = capturedValue
    if isPromo {
        gain[0] += seePieceValue(move.promotionPiece) - seePieceValue(move.pieceValue)
    }
    
    occ ^= Bitboard.bit(at: from)
    
    var nextValue = isPromo ? seePieceValue(move.promotionPiece) : seePieceValue(move.pieceValue)
    stm = stm.getOppositeColor()
    
    while depth < 30 {
        var attackers = seeAttackers(to: to, occupancy: occ, bitboards: bitboards, color: stm)
        guard let (attSquare, attValue, attIsPawn) = popLeastValuableAttacker(
            attackers: &attackers,
            bitboards: bitboards,
            color: stm,
            occupancy: occ
        ) else { break }
        
        let kingCapture = attValue >= seePieceValue(Piece.ColoredPieces.whiteKing.rawValue)
        if kingCapture {
            let replies = seeAttackers(
                to: to,
                occupancy: occ,
                bitboards: bitboards,
                color: stm.getOppositeColor()
            )
            if replies != 0 { break }
        }
        
        depth += 1
        gain[depth] = nextValue - gain[depth - 1]
        
        occ ^= Bitboard.bit(at: attSquare)
        
        nextValue = attValue
        if attIsPawn && isPromotionRank(to, color: stm) {
            nextValue = seePieceValue(Piece.ColoredPieces.whiteQueen.rawValue)
            gain[depth] += nextValue - seePieceValue(Piece.ColoredPieces.whitePawn.rawValue)
        }
        
        stm = stm.getOppositeColor()
    }
    
    while depth > 0 {
        gain[depth - 1] = -max(-gain[depth - 1], gain[depth])
        depth -= 1
    }
    return gain[0]
}

func seePieceValue(_ piece: Int) -> Int {
    abs(PieceValueTable[piece] ?? 0)
}

private func isPromotionRank(_ square: Int, color: Piece.Color) -> Bool {
    color == .white ? square >= 56 : square < 8
}

private func seeAttackers(
    to: Int,
    occupancy occ: Bitboard,
    bitboards: PieceBitboards,
    color: Piece.Color
) -> Bitboard {
    let target = Bitboard.bit(at: to)
    if color == .white {
        var att = generateBlackPawnAttacks(blackPawns: target) & bitboards[Piece.ColoredPieces.whitePawn.rawValue]
        att |= generateKnightAttacks(bitboard: target) & bitboards[Piece.ColoredPieces.whiteKnight.rawValue]
        att |= generateKingAttacks(king: target) & bitboards[Piece.ColoredPieces.whiteKing.rawValue]
        let bishops = bitboards[Piece.ColoredPieces.whiteBishop.rawValue] | bitboards[Piece.ColoredPieces.whiteQueen.rawValue]
        let rooks = bitboards[Piece.ColoredPieces.whiteRook.rawValue] | bitboards[Piece.ColoredPieces.whiteQueen.rawValue]
        att |= rawBishopAttacks(square: to, occupancy: occ) & bishops
        att |= rawRookAttacks(square: to, occupancy: occ) & rooks
        return att & occ
    }
    var att = generateWhitePawnAttacks(whitePawns: target) & bitboards[Piece.ColoredPieces.blackPawn.rawValue]
    att |= generateKnightAttacks(bitboard: target) & bitboards[Piece.ColoredPieces.blackKnight.rawValue]
    att |= generateKingAttacks(king: target) & bitboards[Piece.ColoredPieces.blackKing.rawValue]
    let bishops = bitboards[Piece.ColoredPieces.blackBishop.rawValue] | bitboards[Piece.ColoredPieces.blackQueen.rawValue]
    let rooks = bitboards[Piece.ColoredPieces.blackRook.rawValue] | bitboards[Piece.ColoredPieces.blackQueen.rawValue]
    att |= rawBishopAttacks(square: to, occupancy: occ) & bishops
    att |= rawRookAttacks(square: to, occupancy: occ) & rooks
    return att & occ
}

private func popLeastValuableAttacker(
    attackers: inout Bitboard,
    bitboards: PieceBitboards,
    color: Piece.Color,
    occupancy occ: Bitboard
) -> (square: Int, value: Int, isPawn: Bool)? {
    let pieces: [(Int, Bool)]
    if color == .white {
        pieces = [
            (Piece.ColoredPieces.whitePawn.rawValue, true),
            (Piece.ColoredPieces.whiteKnight.rawValue, false),
            (Piece.ColoredPieces.whiteBishop.rawValue, false),
            (Piece.ColoredPieces.whiteRook.rawValue, false),
            (Piece.ColoredPieces.whiteQueen.rawValue, false),
            (Piece.ColoredPieces.whiteKing.rawValue, false),
        ]
    } else {
        pieces = [
            (Piece.ColoredPieces.blackPawn.rawValue, true),
            (Piece.ColoredPieces.blackKnight.rawValue, false),
            (Piece.ColoredPieces.blackBishop.rawValue, false),
            (Piece.ColoredPieces.blackRook.rawValue, false),
            (Piece.ColoredPieces.blackQueen.rawValue, false),
            (Piece.ColoredPieces.blackKing.rawValue, false),
        ]
    }
    for (piece, isPawn) in pieces {
        let set = attackers & bitboards[piece] & occ
        if set != 0 {
            var copy = set
            let square = Bitboard.popLSB(&copy)
            attackers &= ~Bitboard.bit(at: square)
            return (square, seePieceValue(piece), isPawn)
        }
    }
    return nil
}
