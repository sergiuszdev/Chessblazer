//
//  BoardState.swift
//  Chessblazer
//
//  Created by sergiusz on 10/10/2024.
//

import Foundation

public struct Occupancy: Equatable {
    public var white: Bitboard = 0
    public var black: Bitboard = 0
    
    public var all: Bitboard { white | black }
    
    func friendly(for color: Piece.Color) -> Bitboard {
        color == .white ? white : black
    }
    
    func enemy(for color: Piece.Color) -> Bitboard {
        color == .white ? black : white
    }
    
    static func from(bitboards: PieceBitboards) -> Occupancy {
        bitboards.occupancy()
    }
}

public struct PieceBitboards {
    static let slotCount = 12
    private var slots = [Bitboard](repeating: 0, count: slotCount)
    
    static func slot(for piece: Int) -> Int {
        piece >= Piece.Color.black.rawValue ? piece - 11 : piece - 9
    }
    
    static func piece(forSlot slot: Int) -> Int {
        slot < 6 ? slot + 9 : slot + 11
    }
    
    subscript(piece: Int) -> Bitboard {
        get { slots[Self.slot(for: piece)] }
        set { slots[Self.slot(for: piece)] = newValue }
    }
    
    mutating func addPiece(_ piece: Int, at square: Int) {
        self[piece] |= Bitboard(1) << Bitboard(square)
    }
    
    mutating func removePiece(_ piece: Int, at square: Int) {
        self[piece] &= ~(Bitboard(1) << Bitboard(square))
    }
    
    mutating func movePiece(_ piece: Int, from: Int, to: Int) {
        let fromMask = Bitboard(1) << Bitboard(from)
        let toMask = Bitboard(1) << Bitboard(to)
        self[piece] = (self[piece] & ~fromMask) | toMask
    }
    
    func occupancy() -> Occupancy {
        var occupancy = Occupancy()
        for slot in 0..<6 {
            occupancy.white |= slots[slot]
        }
        for slot in 6..<Self.slotCount {
            occupancy.black |= slots[slot]
        }
        return occupancy
    }
    
    func forEachOccupied(_ body: (_ piece: Int, _ board: Bitboard) -> Void) {
        for slot in 0..<Self.slotCount {
            let board = slots[slot]
            if board != 0 {
                body(Self.piece(forSlot: slot), board)
            }
        }
    }
}

struct UndoInfo {
    var move: Move?
    var lastMove: Move?
    var color: Piece.Color
    var castles: Set<Character>
    var occupancy: Occupancy
    var attackBitboard: Bitboard
    var enPassant: String
    var zobristKey: UInt64
    var currentValidMoves: [Move]?
}

public struct BoardState {
    public var attackBitboard = Bitboard(0)
    public var occupancy = Occupancy()
    var undoStack = [UndoInfo]()
    public var lastMove: Move? = nil
    public var castlesAvailable: Set<Character> = []
    public var currentTurnColor: Piece.Color
    public var bitboards = PieceBitboards()
    public var enPassant = "-"
    public var zobristKey: UInt64 = 0
    public var currentValidMoves: [Move] = [Move]()
    
    public init(currentTurnColor: Piece.Color) {
        self.currentTurnColor = currentTurnColor
    }
    
    mutating func refreshOccupancy() {
        occupancy = bitboards.occupancy()
    }
    
    mutating func refreshZobristKey() {
        zobristKey = Zobrist.compute(self)
    }
    
    func enPassantHashFile() -> Int? {
        if let move = lastMove, let from = move.fromSquare, let target = move.targetSquare {
            if move.pieceValue == Piece.ColoredPieces.whitePawn.rawValue
                && (8...15).contains(from) && (24...31).contains(target) {
                return target % 8
            }
            if move.pieceValue == Piece.ColoredPieces.blackPawn.rawValue
                && (48...55).contains(from) && (32...39).contains(target) {
                return target % 8
            }
            return nil
        }
        if enPassant != "-", let square = translateFromNotationToSquare(enPassant) {
            return square % 8
        }
        return nil
    }
    
    mutating func xorPiece(_ piece: Int, square: Int) {
        zobristKey ^= Zobrist.pieceKey(piece: piece, square: square)
    }
    
    mutating func xorMovePieces(_ move: Move) {
        let from = move.fromSquare!
        let target = move.targetSquare!
        let pieceValue = move.pieceValue
        
        if move.castling {
            xorPiece(pieceValue, square: from)
            xorPiece(pieceValue, square: move.castlingKingDestination)
            xorPiece(move.captureValue, square: move.castlingRookOrigin)
            xorPiece(move.captureValue, square: move.castlingRookDestination)
        } else if move.promotionPiece != 0 {
            xorPiece(pieceValue, square: from)
            if move.captureValue != 0 {
                xorPiece(move.captureValue, square: target)
            }
            xorPiece(move.promotionPiece, square: target)
        } else if move.enPasssantCapture != 0 {
            xorPiece(pieceValue, square: from)
            xorPiece(pieceValue, square: target)
            xorPiece(move.captureValue, square: move.enPasssantCapture)
        } else {
            xorPiece(pieceValue, square: from)
            xorPiece(pieceValue, square: target)
            if move.captureValue != 0 {
                xorPiece(move.captureValue, square: target)
            }
        }
    }
    
    mutating func applyBitboards(_ move: Move) {
        let from = move.fromSquare!
        let target = move.targetSquare!
        let pieceValue = move.pieceValue
        
        if move.castling {
            bitboards.movePiece(pieceValue, from: from, to: move.castlingKingDestination)
            bitboards.movePiece(move.captureValue, from: move.castlingRookOrigin, to: move.castlingRookDestination)
        } else if move.promotionPiece != 0 {
            bitboards.removePiece(pieceValue, at: from)
            if move.captureValue != 0 {
                bitboards.removePiece(move.captureValue, at: target)
            }
            bitboards.addPiece(move.promotionPiece, at: target)
        } else if move.enPasssantCapture != 0 {
            bitboards.movePiece(pieceValue, from: from, to: target)
            bitboards.removePiece(move.captureValue, at: move.enPasssantCapture)
        } else {
            if move.captureValue != 0 {
                bitboards.removePiece(move.captureValue, at: target)
            }
            bitboards.movePiece(pieceValue, from: from, to: target)
        }
    }
    
    mutating func revertBitboards(_ move: Move) {
        let from = move.fromSquare!
        let target = move.targetSquare!
        let pieceValue = move.pieceValue
        
        if move.castling {
            bitboards.movePiece(pieceValue, from: move.castlingKingDestination, to: from)
            bitboards.movePiece(move.captureValue, from: move.castlingRookDestination, to: move.castlingRookOrigin)
        } else if move.promotionPiece != 0 {
            bitboards.removePiece(move.promotionPiece, at: target)
            bitboards.addPiece(pieceValue, at: from)
            if move.captureValue != 0 {
                bitboards.addPiece(move.captureValue, at: target)
            }
        } else if move.enPasssantCapture != 0 {
            bitboards.movePiece(pieceValue, from: target, to: from)
            bitboards.addPiece(move.captureValue, at: move.enPasssantCapture)
        } else {
            bitboards.movePiece(pieceValue, from: target, to: from)
            if move.captureValue != 0 {
                bitboards.addPiece(move.captureValue, at: target)
            }
        }
    }
    
    mutating func updateCastleRights(for move: Move) {
        let from = move.fromSquare!
        let pieceValue = move.pieceValue
        
        if move.castling {
            if pieceValue == Piece.ColoredPieces.whiteKing.rawValue {
                castlesAvailable.remove("K")
                castlesAvailable.remove("Q")
            } else if pieceValue == Piece.ColoredPieces.blackKing.rawValue {
                castlesAvailable.remove("k")
                castlesAvailable.remove("q")
            }
            return
        }
        
        switch pieceValue {
        case Piece.ColoredPieces.whiteKing.rawValue:
            castlesAvailable.remove("K")
            castlesAvailable.remove("Q")
        case Piece.ColoredPieces.blackKing.rawValue:
            castlesAvailable.remove("k")
            castlesAvailable.remove("q")
        case Piece.ColoredPieces.whiteRook.rawValue:
            if from == 0 {
                castlesAvailable.remove("Q")
            } else if from == 7 {
                castlesAvailable.remove("K")
            }
        case Piece.ColoredPieces.blackRook.rawValue:
            if from == 56 {
                castlesAvailable.remove("q")
            } else if from == 63 {
                castlesAvailable.remove("k")
            }
        default:
            break
        }
        
        switch move.captureValue {
        case Piece.ColoredPieces.whiteRook.rawValue:
            if move.targetSquare == 0 {
                castlesAvailable.remove("Q")
            } else if move.targetSquare == 7 {
                castlesAvailable.remove("K")
            }
        case Piece.ColoredPieces.blackRook.rawValue:
            if move.targetSquare == 56 {
                castlesAvailable.remove("q")
            } else if move.targetSquare == 63 {
                castlesAvailable.remove("k")
            }
        default:
            break
        }
    }
    
    mutating func play(_ move: Move, snapshotLegalMoves: Bool) {
        let previousCastles = castlesAvailable
        let previousEpFile = enPassantHashFile()
        undoStack.append(
            UndoInfo(
                move: move,
                lastMove: lastMove,
                color: currentTurnColor,
                castles: castlesAvailable,
                occupancy: occupancy,
                attackBitboard: attackBitboard,
                enPassant: enPassant,
                zobristKey: zobristKey,
                currentValidMoves: snapshotLegalMoves ? currentValidMoves : nil
            )
        )
        applyBitboards(move)
        updateCastleRights(for: move)
        lastMove = move
        enPassant = "-"
        currentTurnColor = currentTurnColor.getOppositeColor()
        refreshOccupancy()
        attackBitboard = generateAllAttackedSquares(
            bitboards: bitboards,
            currentColor: currentTurnColor,
            occupancy: occupancy
        )
        xorMovePieces(move)
        zobristKey ^= Zobrist.castleKey(previousCastles)
        zobristKey ^= Zobrist.castleKey(castlesAvailable)
        zobristKey ^= Zobrist.blackToMove
        zobristKey ^= Zobrist.enPassantKey(previousEpFile)
        zobristKey ^= Zobrist.enPassantKey(enPassantHashFile())
    }
    
    mutating func playNull() {
        let previousEpFile = enPassantHashFile()
        undoStack.append(
            UndoInfo(
                move: nil,
                lastMove: lastMove,
                color: currentTurnColor,
                castles: castlesAvailable,
                occupancy: occupancy,
                attackBitboard: attackBitboard,
                enPassant: enPassant,
                zobristKey: zobristKey,
                currentValidMoves: nil
            )
        )
        lastMove = nil
        enPassant = "-"
        currentTurnColor = currentTurnColor.getOppositeColor()
        attackBitboard = generateAllAttackedSquares(
            bitboards: bitboards,
            currentColor: currentTurnColor,
            occupancy: occupancy
        )
        zobristKey ^= Zobrist.blackToMove
        zobristKey ^= Zobrist.enPassantKey(previousEpFile)
        zobristKey ^= Zobrist.enPassantKey(enPassantHashFile())
    }
    
    mutating func unplay() {
        guard let undo = undoStack.popLast() else { return }
        if let move = undo.move {
            revertBitboards(move)
        }
        lastMove = undo.lastMove
        currentTurnColor = undo.color
        castlesAvailable = undo.castles
        occupancy = undo.occupancy
        attackBitboard = undo.attackBitboard
        enPassant = undo.enPassant
        zobristKey = undo.zobristKey
        if let moves = undo.currentValidMoves {
            currentValidMoves = moves
        }
    }
}

public enum GameResult {
    case white, black, draw, none
}

public struct BoardData {
    public var halfMoves = 0
    public var hasGameEnded = false
    public var gameResult: GameResult = .none
    
    public init() {}
}
