//
//  Move.swift
//  Chessblazer
//
//  Created by sergiusz on 26/07/2024.
//

import Foundation

public struct Move: Equatable, Hashable, Comparable, Codable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fromSquare!+targetSquare!+enPasssantCapture)
    }
    
    public var castlingRookOrigin = 0
    public var castlingRookDestination = 0
    public var castlingKingDestination = 0
    public var promotionPiece: Int = 0
    public var enPasssantCapture = 0
    public var pieceValue: Int = 0
    public var captureValue = 0
    
    public var fromSquare: Int?
    public var targetSquare: Int?
    
    
    public var castling: Bool { castlingRookDestination != 0 || castlingKingDestination != 0}

    
    public init(fromSquare: Int, targetSquare: Int, enPasssantCapture: Int, pieceValue: Int, captureValue: Int) {
        self.fromSquare = fromSquare
        self.targetSquare = targetSquare
        self.enPasssantCapture = enPasssantCapture
        self.pieceValue = pieceValue
        self.captureValue = captureValue
    }
    
    public init(fromSquare: Int, targetSquare: Int, pieceValue: Int,  captureValue: Int) {
        self.fromSquare = fromSquare
        self.targetSquare = targetSquare
        self.captureValue = captureValue
        self.pieceValue = pieceValue
    }
    
    public init(fromSquare: Int, targetSquare: Int, pieceValue: Int,  captureValue: Int, promotionPiece: Int) {
        self.fromSquare = fromSquare
        self.targetSquare = targetSquare
        self.captureValue = captureValue
        self.pieceValue = pieceValue
        self.promotionPiece = promotionPiece
    }
    
    public init(kingFrom: Int, kingTo: Int, rookFrom: Int, rookTo: Int, kingValue: Int, rookValue: Int) {
        self.fromSquare = kingFrom
        self.targetSquare = kingTo
        self.pieceValue = kingValue
        self.captureValue = rookValue
        self.castlingKingDestination = kingTo
        self.castlingRookOrigin = rookFrom
        self.castlingRookDestination = rookTo
    }
    
    public static func == (lhs: Move, rhs: Move) -> Bool {
        return (lhs.fromSquare == rhs.fromSquare) && (lhs.targetSquare == rhs.targetSquare)
    }
    
    func moveValue(attackPawnTable: Bitboard = Bitboard(0)) -> Int {
        var score = 0
        let pieceRealValue = abs(PieceValueTable[pieceValue] ?? 0)
        let captureRealValue = abs(PieceValueTable[captureValue] ?? 0)

        if captureValue != 0 && !castling {
            score += captureRealValue * 10 - pieceRealValue
        }
        
        if promotionPiece != 0 {
            score += abs(PieceValueTable[promotionPiece] ?? promotionPiece)
        }

        let b = (Bitboard(1) << Bitboard(targetSquare!))
        if b & attackPawnTable == b {
            score -= pieceRealValue
        }
        return score
    }
    
    public static func < (lhs: Move, rhs: Move) -> Bool {
        return lhs.moveValue() < rhs.moveValue()
    }
    public init(notation: String) {
                
        if notation.count == 4 {
            self.fromSquare = translateFromNotationToSquare(String(notation.prefix(2)))
            self.targetSquare = translateFromNotationToSquare(String(notation.suffix(2)))
        } else {
            self.fromSquare = translateFromNotationToSquare(String(notation.prefix(2)))
            
            let start = notation.index(notation.startIndex, offsetBy: 2)
            let end = notation.index(notation.startIndex, offsetBy: 4)
            self.targetSquare = translateFromNotationToSquare(String(notation[start..<end]))
            if let pp = Piece.ColoredPiecesDict[String(notation.suffix(1))] {
                self.promotionPiece = pp.rawValue
            }
        }
        self.pieceValue = 0
    }

}
