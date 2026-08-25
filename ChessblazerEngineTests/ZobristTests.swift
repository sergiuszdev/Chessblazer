import Testing

@Suite("Zobrist")
struct ZobristTests {
    @Test func startposKeyIsNonZeroAndMatchesCompute() {
        let game = Game()
        #expect(game.boardState.zobristKey != 0)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
    }
    
    @Test func incrementalPlayMatchesFullRecompute() {
        let game = Game()
        let move = game.boardState.currentValidMoves.first { moveToNotation(move: $0) == "e2e4" }!
        game.play(move)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
    }
    
    @Test func unplayRestoresKey() {
        let game = Game()
        let startKey = game.boardState.zobristKey
        let move = game.boardState.currentValidMoves.first { moveToNotation(move: $0) == "e2e4" }!
        game.play(move)
        game.unplay()
        #expect(game.boardState.zobristKey == startKey)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
    }
    
    @Test func startposThenE4MatchesFen() {
        let played = Game()
        let e2e4 = played.boardState.currentValidMoves.first { moveToNotation(move: $0) == "e2e4" }!
        played.play(e2e4)
        
        let fromFen = Game()
        fromFen.loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
        #expect(played.boardState.zobristKey == fromFen.boardState.zobristKey)
    }
    
    @Test func castlePlayUnplayKeepsKeyConsistent() {
        let game = Game()
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let startKey = game.boardState.zobristKey
        let castle = game.findMove(notation: "e1g1")!
        game.play(castle)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
        game.unplay()
        #expect(game.boardState.zobristKey == startKey)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
    }
    
    @Test func promotionAndEnPassantMatchCompute() {
        let promo = Game()
        promo.loadFromFen(fen: "8/P5k1/8/8/8/8/8/K7 w - - 0 1")
        let queen = promo.findMove(notation: "a7a8q")!
        promo.play(queen)
        #expect(promo.boardState.zobristKey == Zobrist.compute(promo.boardState))
        
        let ep = Game()
        for notation in ["e2e4", "d7d5", "e4e5", "f7f5"] {
            let move = generateAllLegalMoves(boardState: ep.boardState)
                .first { moveToNotation(move: $0) == notation }!
            ep.play(move)
            #expect(ep.boardState.zobristKey == Zobrist.compute(ep.boardState))
        }
        
        let fromFen = Game()
        fromFen.loadFromFen(fen: "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3")
        #expect(ep.boardState.zobristKey == fromFen.boardState.zobristKey)
        
        let capture = generateAllLegalMoves(boardState: ep.boardState)
            .first { $0.enPasssantCapture != 0 }!
        ep.play(capture)
        #expect(ep.boardState.zobristKey == Zobrist.compute(ep.boardState))
    }
    
    @Test func searchDoesNotLeakKey() {
        let game = Game()
        let startKey = game.boardState.zobristKey
        _ = findBestMove(game: game, depth: 2, maximizingPlayer: true)
        #expect(game.boardState.undoStack.isEmpty)
        #expect(game.boardState.zobristKey == startKey)
        #expect(game.boardState.zobristKey == Zobrist.compute(game.boardState))
    }
}
