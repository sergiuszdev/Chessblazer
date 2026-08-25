//
//  Pieces.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

class Piece {
    enum PieceType: Int {
        case empty = 0
        case king = 1
        case pawn = 2
        case knight = 3
        case bishop = 4
        case rook = 5
        case queen = 6
    }
    
    
    enum Color: Int {
        case white = 8
        case black = 16
        case none = 0
        func getOppositeColor() -> Color {
            if self == .white {
                return .black
            } else {
                return .white
            }
        }
    }
    
    enum ColoredPieces: Int, CaseIterable {
        
        case empty = 0
        case blackKing = 17
        case blackPawn = 18
        case blackQueen = 22
        case blackKnight = 19
        case blackBishop = 20
        case blackRook = 21
    
        case whiteKing = 9
        case whitePawn = 10
        case whiteQueen = 14
        case whiteKnight = 11
        case whiteBishop = 12
        case whiteRook = 13
        
        static func possibleWhitePromotions() -> [ColoredPieces] {
            return [.whiteQueen, .whiteRook, .whiteKnight, .whiteBishop]
        }
        
        static func possibleBlackPromotions() -> [ColoredPieces] {
            return [.blackQueen, .blackRook, .blackKnight, .blackBishop]
        }
        
    }
    
    static func combine(type: PieceType, color: Color) -> Int {
        return type.rawValue | color.rawValue
    }
    
    static func getType(piece: Int) -> PieceType {
        let colorValue = checkColor(piece: piece) == .white ? Color.white.rawValue : Color.black.rawValue
        let noColorPiece = piece - colorValue
        return PieceType(rawValue: noColorPiece) ?? PieceType.empty
        
    }
    
    
    static func checkColor(piece: Int) -> Piece.Color {
        if piece / Piece.Color.black.rawValue == 1 {
            return .black
        } else {
            return .white
        }
    }
    
    static let PiecesDict: [Character: PieceType] = [
        "0": PieceType.empty,
        "k": PieceType.king,
        "p": PieceType.pawn,
        "n": PieceType.knight,
        "b": PieceType.bishop,
        "r": PieceType.rook,
        "q": PieceType.queen
    ]
    
    static let ColoredPiecesDict: [String: ColoredPieces] = [
        "k": ColoredPieces.blackKing,
        "p": ColoredPieces.blackPawn,
        "n": ColoredPieces.blackKnight,
        "b": ColoredPieces.blackBishop,
        "r": ColoredPieces.blackRook,
        "q": ColoredPieces.blackQueen,
        
        "K": ColoredPieces.whiteKing,
        "P": ColoredPieces.whitePawn,
        "N": ColoredPieces.whiteKnight,
        "B": ColoredPieces.whiteBishop,
        "R": ColoredPieces.whiteRook,
        "Q": ColoredPieces.whiteQueen
        
    ]
    
    static let ValueToPieceDict: [Int: Character] = [
        0: ".",
        combine(type: .king, color: .black): "k",
        combine(type: .pawn, color: .black): "p",
        combine(type: .knight, color: .black): "n",
        combine(type: .bishop, color: .black): "b",
        combine(type: .rook, color: .black): "r",
        combine(type: .queen, color: .black): "q",
        combine(type: .king, color: .white): "K",
        combine(type: .pawn, color: .white): "P",
        combine(type: .knight, color: .white): "N",
        combine(type: .bishop, color: .white): "B",
        combine(type: .rook, color: .white): "R",
        combine(type: .queen, color: .white): "Q"
    ]
    
    // ♚ ♛ ♝ ♞ ♟ ♜
    // ♔ ♕ ♗ ♘ ♙ ♖
    
    static let ValueToPieceEmojiDict: [Int: Character] = [
        0: ".",
        combine(type: .king, color: .black): "♚",
        combine(type: .pawn, color: .black): "♟",
        combine(type: .knight, color: .black): "♞",
        combine(type: .bishop, color: .black): "♝",
        combine(type: .rook, color: .black): "♜",
        combine(type: .queen, color: .black): "♛",
        combine(type: .king, color: .white): "♔",
        combine(type: .pawn, color: .white): "♙",
        combine(type: .knight, color: .white): "♘",
        combine(type: .bishop, color: .white): "♗",
        combine(type: .rook, color: .white): "♖",
        combine(type: .queen, color: .white): "♕"
    ]
}

