// Minimal human-vs-engine loop using the Chessblazer Swift library.
// Not a build target — copy into your app or run in a Swift package executable.
//
// Requires: .package dependency on Chessblazer
// See docs/integration/swift-library.md

import Chessblazer
import Foundation

// moveToNotation isn't public yet — small helper for printing
func uciNotation(for move: Move) -> String {
    guard let from = move.fromSquare, let to = move.targetSquare else { return "0000" }
    let files = "abcdefgh"
    func square(_ s: Int) -> String {
        let f = files[files.index(files.startIndex, offsetBy: s % 8)]
        return "\(f)\(s / 8 + 1)"
    }
    var notation = "\(square(from))\(square(to))"
    if move.promotionPiece != 0 {
        let letter: String
        switch Piece.getType(piece: move.promotionPiece) {
        case .queen:  letter = "q"
        case .rook:   letter = "r"
        case .bishop: letter = "b"
        case .knight: letter = "n"
        default:      letter = ""
        }
        notation += letter
    }
    return notation
}

func printBoard(_ game: Game) {
    let squares = game.toBoardArrayRepresentation()
    let files = "abcdefgh"
    for rank in (0..<8).reversed() {
        print(rank + 1, terminator: " ")
        for file in 0..<8 {
            let piece = squares[rank * 8 + file]
            if piece == 0 {
                print(".", terminator: " ")
            } else {
                let color = Piece.checkColor(piece: piece) == .white ? "w" : "b"
                let sym: String
                switch Piece.getType(piece: piece) {
                case .king:   sym = "K"
                case .queen:  sym = "Q"
                case .rook:   sym = "R"
                case .bishop: sym = "B"
                case .knight: sym = "N"
                case .pawn:   sym = "P"
                default:     sym = "?"
                }
                print("\(color)\(sym)", terminator: " ")
            }
        }
        print()
    }
    print("  \(files)")
    let turn = game.boardState.currentTurnColor == .white ? "white" : "black"
    print("to move: \(turn)\n")
}

@main
struct MinimalChessApp {
    static func main() {
        let game = Game()
        let searchDepth = 5

        print("Chessblazer — type moves as UCI (e2e4), 'quit' to exit\n")
        printBoard(game)

        while !game.boardData.hasGameEnded {
            let whiteToMove = game.boardState.currentTurnColor == .white

            if whiteToMove {
                // human plays white
                print("Your move: ", terminator: "")
                guard let line = readLine()?.trimmingCharacters(in: .whitespaces), !line.isEmpty else { continue }
                if line == "quit" { break }
                guard let move = game.findMove(notation: line.lowercased()) else {
                    print("illegal move\n")
                    continue
                }
                game.makeMove(move: move)
            } else {
                // engine plays black
                print("Engine thinking (depth \(searchDepth))…")
                guard let move = findBestMove(game: game, depth: searchDepth, maximizingPlayer: false) else {
                    print("engine has no move\n")
                    break
                }
                print("Engine: \(uciNotation(for: move))\n")
                game.makeMove(move: move)
            }

            printBoard(game)
        }

        if game.boardData.hasGameEnded {
            switch game.boardData.gameResult {
            case .white: print("White wins")
            case .black: print("Black wins")
            case .draw:  print("Draw")
            case .none:   break
            }
        }
    }
}
