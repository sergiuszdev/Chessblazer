import Testing

/// Regression for https://lichess.org/EgaJElwq
///
/// Lichess rejected `bestmove a8b8` in
/// `r4rk1/pp1n1ppp/2p1pn2/6q1/PN6/3P1P2/1BP1KPBP/2RQ2R1 w - - 5 16`.
/// Black had just castled (`e8g8`). The engine encoded castling as king-to-rook
/// (`e8h8`), dropped the move, searched as Black, and played Ra8-b8.
@Suite("Lichess illegal move EgaJElwq")
struct LichessIllegalMoveTests {
    private let crashFen = "r4rk1/pp1n1ppp/2p1pn2/6q1/PN6/3P1P2/1BP1KPBP/2RQ2R1 w - - 5 16"
    private let uciMoves = [
        "b1c3", "c7c6", "g1f3", "d7d6", "e2e4", "d6d5", "e4e5", "c8g4",
        "a2a4", "b8d7", "d2d3", "g4f3", "g2f3", "e7e6", "e1e2", "d8c7",
        "b2b4", "f8b4", "c1b2", "d7e5", "f1g2", "e5d7", "c3d5", "c7a5",
        "d5b4", "a5g5", "h1g1", "g8f6", "a1c1", "e8g8"
    ]
    
    @Test func positionCommandAppliesBlackKingsideCastle() {
        let engine = Engine()
        engine.processInput(command: "position startpos moves " + uciMoves.joined(separator: " "))
        
        #expect(engine.game.boardState.currentTurnColor == .white)
        #expect(piece(on: "g8", in: engine.game) == Piece.ColoredPieces.blackKing.rawValue)
        #expect(piece(on: "f8", in: engine.game) == Piece.ColoredPieces.blackRook.rawValue)
        #expect(piece(on: "e8", in: engine.game) == 0)
        #expect(engine.game.findMove(notation: "a8b8") == nil)
    }
    
    @Test func crashFenDoesNotAllowA8B8() {
        let game = Game()
        game.loadFromFen(fen: crashFen)
        
        #expect(game.boardState.currentTurnColor == .white)
        let legal = legalNotations(in: game)
        #expect(!legal.contains("a8b8"))
        #expect(game.findMove(notation: "a8b8") == nil)
        
        let best = findBestMove(game: game, depth: 1, maximizingPlayer: true)
        #expect(best != nil)
        #expect(moveToNotation(move: best!) != "a8b8")
        #expect(legal.contains(moveToNotation(move: best!)))
        #expect(Piece.checkColor(piece: best!.pieceValue) == .white)
    }
    
    @Test func searchAfterReplayedGameDoesNotPlayA8B8() {
        let engine = Engine()
        engine.processInput(command: "position startpos moves " + uciMoves.joined(separator: " "))
        
        let legal = legalNotations(in: engine.game)
        #expect(!legal.contains("a8b8"))
        
        let best = findBestMove(game: engine.game, depth: 1, maximizingPlayer: true)
        #expect(best != nil)
        #expect(moveToNotation(move: best!) != "a8b8")
        #expect(legal.contains(moveToNotation(move: best!)))
        #expect(Piece.checkColor(piece: best!.pieceValue) == .white)
    }
    
    private func legalNotations(in game: Game) -> Set<String> {
        Set(game.boardState.currentValidMoves.map(moveToNotation))
    }
    
    private func piece(on square: String, in game: Game) -> Int {
        guard let index = translateFromNotationToSquare(square) else { return -1 }
        return game.toBoardArrayRepresentation()[index]
    }
}
