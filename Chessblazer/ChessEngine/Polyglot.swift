//
//  Polyglot.swift
//  Chessblazer
//
//  Polyglot .bin opening books: hash, decode, and probe.
//  Spec: http://hgm.nubati.net/book_format.html
//

import Foundation

struct PolyglotEntry {
    let key: UInt64
    let rawMove: UInt16
    let weight: UInt16
    let learn: UInt32
}

enum Polyglot {
    static let startposKey: UInt64 = 0x463B96181691FC9C
    
    static func hash(_ board: BoardState) -> UInt64 {
        var key: UInt64 = 0
        board.bitboards.forEachOccupied { piece, bitboard in
            guard let pieceIndex = pieceIndex(piece) else { return }
            var copy = bitboard
            while copy != 0 {
                let square = Bitboard.popLSB(&copy)
                key ^= PolyglotKeys.random64[64 * pieceIndex + square]
            }
        }
        if board.castlesAvailable.contains("K") { key ^= PolyglotKeys.random64[768] }
        if board.castlesAvailable.contains("Q") { key ^= PolyglotKeys.random64[769] }
        if board.castlesAvailable.contains("k") { key ^= PolyglotKeys.random64[770] }
        if board.castlesAvailable.contains("q") { key ^= PolyglotKeys.random64[771] }
        if let file = enPassantFile(board) {
            key ^= PolyglotKeys.random64[772 + file]
        }
        if board.currentTurnColor == .white {
            key ^= PolyglotKeys.random64[780]
        }
        return key
    }
    
    /// Polyglot encodes castling as king-to-rook (`e1h1`). Map that onto UCI king destination.
    static func decodeMove(_ raw: UInt16, legalMoves: [Move], bitboards: PieceBitboards) -> Move? {
        guard raw != 0 else { return nil }
        let toFile = Int(raw & 7)
        let toRow = Int((raw >> 3) & 7)
        let fromFile = Int((raw >> 6) & 7)
        let fromRow = Int((raw >> 9) & 7)
        let promoCode = Int((raw >> 12) & 7)
        let from = fromRow * 8 + fromFile
        var to = toRow * 8 + toFile
        let promoType = promotionType(promoCode)
        
        let piece = getPieceValueFromField(at: from, bitboards: bitboards)
        if Piece.getType(piece: piece) == .king {
            if from == 4 && to == 7 { to = 6 }
            else if from == 4 && to == 0 { to = 2 }
            else if from == 60 && to == 63 { to = 62 }
            else if from == 60 && to == 56 { to = 58 }
        }
        
        return legalMoves.first { legal in
            legal.fromSquare == from
                && legal.targetSquare == to
                && (promoType == nil || Piece.getType(piece: legal.promotionPiece) == promoType)
        }
    }
    
    static func encodeMove(from: Int, to: Int, promotion: Int = 0) -> UInt16 {
        let toFile = UInt16(to % 8)
        let toRow = UInt16(to / 8)
        let fromFile = UInt16(from % 8)
        let fromRow = UInt16(from / 8)
        return toFile | (toRow << 3) | (fromFile << 6) | (fromRow << 9) | (UInt16(promotion) << 12)
    }
    
    static func makeBookData(entries: [PolyglotEntry]) -> Data {
        let sorted = entries.sorted { $0.key < $1.key }
        var data = Data(capacity: sorted.count * 16)
        for entry in sorted {
            appendBigEndian(&data, entry.key)
            appendBigEndian(&data, entry.rawMove)
            appendBigEndian(&data, entry.weight)
            appendBigEndian(&data, entry.learn)
        }
        return data
    }
    
    private static func pieceIndex(_ piece: Int) -> Int? {
        let color = Piece.checkColor(piece: piece) == .white ? 1 : 0
        let type: Int
        switch Piece.getType(piece: piece) {
        case .pawn: type = 0
        case .knight: type = 1
        case .bishop: type = 2
        case .rook: type = 3
        case .queen: type = 4
        case .king: type = 5
        default: return nil
        }
        return type * 2 + color
    }
    
    private static func promotionType(_ code: Int) -> Piece.PieceType? {
        switch code {
        case 1: return .knight
        case 2: return .bishop
        case 3: return .rook
        case 4: return .queen
        default: return nil
        }
    }
    
    /// Polyglot only hashes EP when a pawn of the side to move can actually capture.
    private static func enPassantFile(_ board: BoardState) -> Int? {
        let epSquare: Int
        if let move = board.lastMove, let from = move.fromSquare, let target = move.targetSquare {
            if move.pieceValue == Piece.ColoredPieces.whitePawn.rawValue
                && (8...15).contains(from) && (24...31).contains(target) {
                epSquare = target - 8
            } else if move.pieceValue == Piece.ColoredPieces.blackPawn.rawValue
                && (48...55).contains(from) && (32...39).contains(target) {
                epSquare = target + 8
            } else {
                return nil
            }
        } else if board.enPassant != "-", let square = translateFromNotationToSquare(board.enPassant) {
            epSquare = square
        } else {
            return nil
        }
        
        let pawns: Bitboard
        let attacks: Bitboard
        if board.currentTurnColor == .white {
            pawns = board.bitboards[Piece.ColoredPieces.whitePawn.rawValue]
            attacks = generateWhitePawnAttacks(whitePawns: pawns)
        } else {
            pawns = board.bitboards[Piece.ColoredPieces.blackPawn.rawValue]
            attacks = generateBlackPawnAttacks(blackPawns: pawns)
        }
        guard attacks & Bitboard.bit(at: epSquare) != 0 else { return nil }
        return epSquare % 8
    }
    
    private static func appendBigEndian(_ data: inout Data, _ value: UInt64) {
        var be = value.bigEndian
        withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
    }
    
    private static func appendBigEndian(_ data: inout Data, _ value: UInt32) {
        var be = value.bigEndian
        withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
    }
    
    private static func appendBigEndian(_ data: inout Data, _ value: UInt16) {
        var be = value.bigEndian
        withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
    }
}

final class PolyglotBook {
    private let data: Data
    private let entryCount: Int
    
    convenience init?(path: String) {
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        self.init(data: data)
    }
    
    init?(data: Data) {
        guard data.count % 16 == 0 else { return nil }
        self.data = data
        entryCount = data.count / 16
    }
    
    func entries(for key: UInt64) -> [PolyglotEntry] {
        guard let start = firstIndex(of: key) else { return [] }
        var result = [PolyglotEntry]()
        var index = start
        while index < entryCount {
            let entry = entry(at: index)
            if entry.key != key { break }
            result.append(entry)
            index += 1
        }
        return result
    }
    
    func chooseMove(boardState: BoardState, variety: Bool) -> Move? {
        let key = Polyglot.hash(boardState)
        let candidates = entries(for: key).filter { $0.weight >= 1 }
        var legal = [(move: Move, weight: UInt16)]()
        for entry in candidates {
            if let move = Polyglot.decodeMove(
                entry.rawMove,
                legalMoves: boardState.currentValidMoves,
                bitboards: boardState.bitboards
            ) {
                legal.append((move, entry.weight))
            }
        }
        guard !legal.isEmpty else { return nil }
        if !variety {
            return legal.max(by: { $0.weight < $1.weight })?.move
        }
        let total = legal.reduce(0) { $0 + Int($1.weight) }
        var pick = Int.random(in: 0..<max(total, 1))
        for item in legal {
            pick -= Int(item.weight)
            if pick < 0 { return item.move }
        }
        return legal.last?.move
    }
    
    private func firstIndex(of key: UInt64) -> Int? {
        var low = 0
        var high = entryCount
        while low < high {
            let mid = (low + high) / 2
            let midKey = self.key(at: mid)
            if midKey < key {
                low = mid + 1
            } else {
                high = mid
            }
        }
        guard low < entryCount, self.key(at: low) == key else { return nil }
        return low
    }
    
    private func key(at index: Int) -> UInt64 {
        readUInt64(at: index * 16)
    }
    
    private func entry(at index: Int) -> PolyglotEntry {
        let offset = index * 16
        return PolyglotEntry(
            key: readUInt64(at: offset),
            rawMove: readUInt16(at: offset + 8),
            weight: readUInt16(at: offset + 10),
            learn: readUInt32(at: offset + 12)
        )
    }
    
    private func readUInt16(at offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }
    
    private func readUInt32(at offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24
            | UInt32(data[offset + 1]) << 16
            | UInt32(data[offset + 2]) << 8
            | UInt32(data[offset + 3])
    }
    
    private func readUInt64(at offset: Int) -> UInt64 {
        var value: UInt64 = 0
        for i in 0..<8 {
            value = (value << 8) | UInt64(data[offset + i])
        }
        return value
    }
}
