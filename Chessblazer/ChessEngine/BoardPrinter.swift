//
//  BoardTerminalGUI.swift
//  Chessblazer
//
//  Created by sergiusz on 26/07/2024.
//

import Foundation
class BoardPrinter {
    
    func printBoard(board: [Int], emojiMode: Bool = true, perspectiveColor: Piece.Color = .white) {
        perspectiveColor == .white ? printBoardFromWhitePerspective(board: board, emojiMode: emojiMode) : printBoardBlackPerspective(board: board, emojiMode: emojiMode)
        
    }
    
    private func printBoardBlackPerspective(board: [Int], emojiMode: Bool = false) {
        let letters = (65...72).map { String(UnicodeScalar($0)!) }
        var numbers = 1
        
        for (index, value) in board.enumerated() {
            if index % 8 == 0 {
                print("")
                print(numbers, terminator: "")
                numbers += 1
            }
            if let pieceChar = emojiMode ? Piece.ValueToPieceEmojiDict[value] : Piece.ValueToPieceDict[value] {
                print(" \(pieceChar)", terminator: " ")
            } else {
                print(" ?", terminator: " ")
            }
            
            
        }
        print()
        for letter in letters {
            print("  \(letter)", terminator: "")
        }
        
        print("")
    }
    

    
    private func printBoardFromWhitePerspective(board: [Int], emojiMode: Bool = false) {
        let letters = (65...72).map { String(UnicodeScalar($0)!) }
        var numbers = 8
        
        for row in 0..<8 {
            let startIndex = (7 - row) * 8
            let endIndex = startIndex + 8
            let rowValues = board[startIndex..<endIndex]
            
            print("")
            print(numbers, terminator: "")
            numbers -= 1
            
            for value in rowValues {
                if let pieceChar = emojiMode ? Piece.ValueToPieceEmojiDict[value] : Piece.ValueToPieceDict[value] {
                    print(" \(pieceChar)", terminator: " ")
                } else {
                    print(" ?", terminator: " ")
                }
            }
        }
        
        print()
        for letter in letters {
            print("  \(letter)", terminator: "")
        }
        
        print("")
    }
}
