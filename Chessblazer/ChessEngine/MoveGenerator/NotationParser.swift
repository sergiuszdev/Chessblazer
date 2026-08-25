//
//  NotationParser.swift
//  Chessblazer
//
//  Created by sergiusz on 29/01/2025.
//

import Foundation

let letterToNumber: [String : Int] = [
    "A" : 0,
    "B" : 1,
    "C" : 2,
    "D" : 3,
    "E" : 4,
    "F" : 5,
    "G" : 6,
    "H" : 7,
]

func squareToNotation(square: Int) -> String {
    let ranks = square / 8 + 1
    let files = square % 8
    let letters = "abcdefgh"

    guard ranks >= 1 && ranks <= 8 && files >= 0 && files < 8 else {
        return "Invalid square"
    }

    let fileLetter = letters[letters.index(letters.startIndex, offsetBy: files)]
    return "\(fileLetter)\(ranks)"
}

func translateFromNotationToSquare(_ notation: String) -> Int? {
    guard notation.count == 2 else { return nil }
    let letter = String(notation.prefix(1))
    guard let fileIndex = letterToNumber[letter.uppercased()] else { return nil }
    guard let rankNumber: Int = Int(String(notation.suffix(1))), rankNumber >= 1, rankNumber <= 8 else { return nil }
    let rankIndex = rankNumber - 1
    return 8 * rankIndex + fileIndex
}

func uciPromotionLetter(piece: Int) -> String? {
    switch Piece.getType(piece: piece) {
    case .queen: return "q"
    case .rook: return "r"
    case .bishop: return "b"
    case .knight: return "n"
    default: return nil
    }
}

func moveToNotation(move: Move) -> String {
    guard let from = move.fromSquare, let to = move.targetSquare else { return "0000" }
    var notation = "\(squareToNotation(square: from))\(squareToNotation(square: to))"
    if move.promotionPiece != 0, let letter = uciPromotionLetter(piece: move.promotionPiece) {
        notation += letter
    }
    return notation
}
