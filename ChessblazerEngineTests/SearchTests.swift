import Testing

@Suite("Search")
struct SearchTests {
    @Test func goParsesExplicitLimits() {
        let go = UciGoInput.parse(from: "go depth 8 movetime 1500 wtime 300000 btime 300000")
        #expect(go.depth == 8)
        #expect(go.searchMoveTime == 1500)
        #expect(go.whiteTime == 300000)
        #expect(go.blackTime == 300000)
        
        let fromMovetime = SearchLimits.from(go: go, sideToMove: .white)
        #expect(fromMovetime.maxDepth == 8)
        #expect(fromMovetime.allocatedTime == 1.5)
    }
    
    @Test func goDepthOnlyHasNoTimeCap() {
        let go = UciGoInput.parse(from: "go depth 4")
        let limits = SearchLimits.from(go: go, sideToMove: .white)
        #expect(limits.maxDepth == 4)
        #expect(limits.allocatedTime == nil)
    }
    
    @Test func mateInOne() {
        let game = Game()
        game.loadFromFen(fen: "6k1/8/6K1/8/8/8/8/4R3 w - - 0 1")
        let move = findBestMove(game: game, depth: 1, maximizingPlayer: true)
        #expect(moveToNotation(move: move!) == "e1e8")
    }
    
    @Test func mateInOneSurvivesNullMoveAndLmr() {
        let game = Game()
        game.loadFromFen(fen: "6k1/8/6K1/8/8/8/8/4R3 w - - 0 1")
        let move = findBestMove(game: game, depth: 4, maximizingPlayer: true)
        #expect(moveToNotation(move: move!) == "e1e8")
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func stalemateIsDraw() {
        let game = Game()
        game.loadFromFen(fen: "k7/8/1Q6/8/8/8/8/K7 b - - 0 1")
        #expect(game.boardState.currentValidMoves.isEmpty)
        #expect(terminalScore(game: game, ply: 0) == 0)
    }
    
    @Test func promotionUsesUciPieceLetter() {
        let game = Game()
        game.loadFromFen(fen: "8/P5k1/8/8/8/8/8/K7 w - - 0 1")
        let queen = game.findMove(notation: "a7a8q")
        let knight = game.findMove(notation: "a7a8n")
        #expect(queen != nil)
        #expect(knight != nil)
        #expect(moveToNotation(move: queen!) == "a7a8q")
        #expect(moveToNotation(move: knight!) == "a7a8n")
        #expect(Piece.getType(piece: queen!.promotionPiece) == .queen)
        #expect(Piece.getType(piece: knight!.promotionPiece) == .knight)
        #expect(game.findMove(notation: "a7a8") != nil)
        #expect(game.findMove(notation: "e2e4") == nil)
    }
    
    @Test func cancelledSearchStillReturnsALegalMove() {
        let game = Game()
        let move = findBestMove(
            game: game,
            limits: SearchLimits(maxDepth: 20, allocatedTime: nil),
            maximizingPlayer: true,
            isCancelled: { true }
        )
        #expect(move != nil)
        #expect(game.boardState.currentValidMoves.contains(move!))
    }
    
    @Test func setOptionParsesSpacedNames() {
        let parsed = parseUciSetOption(args: ["setoption", "name", "Move", "Overhead", "value", "2000"])
        #expect(parsed?.name == "Move Overhead")
        #expect(parsed?.value == "2000")
        
        var options = EngineUciOptions()
        options.set(name: parsed!.name, value: parsed!.value)
        #expect(options.moveOverheadMs == 2000)
        
        let advertised = EngineUciOptions.advertised.map(\.name)
        #expect(advertised.contains("Move Overhead"))
        #expect(advertised.contains("Hash"))
        #expect(advertised.contains("Threads"))
        
        options.set(name: "Hash", value: "64")
        #expect(options.hashSizeMB == 64)
        
        let threads = EngineUciOptions.advertised.first { $0.name == "Threads" }
        #expect(threads?.min == 1)
        #expect((threads?.max ?? 0) >= 4)
        #expect(threads?.advertisement.contains("max 256") == true)
    }
    
    @Test func castleUsesUciKingDestination() {
        let game = Game()
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let whiteKingSide = game.findMove(notation: "e1g1")
        let whiteQueenSide = game.findMove(notation: "e1c1")
        #expect(whiteKingSide != nil)
        #expect(whiteQueenSide != nil)
        #expect(whiteKingSide?.castling == true)
        #expect(moveToNotation(move: whiteKingSide!) == "e1g1")
        #expect(moveToNotation(move: whiteQueenSide!) == "e1c1")
        #expect(game.findMove(notation: "e1h1") == nil)
        
        game.makeMove(move: whiteKingSide!)
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R b KQkq -")
        let blackKingSide = game.findMove(notation: "e8g8")
        let blackQueenSide = game.findMove(notation: "e8c8")
        #expect(blackKingSide != nil)
        #expect(blackQueenSide != nil)
        #expect(moveToNotation(move: blackKingSide!) == "e8g8")
        #expect(moveToNotation(move: blackQueenSide!) == "e8c8")
    }
    
    @Test func playUnplayRestoresPosition() {
        let game = Game()
        let startBoard = game.toBoardArrayRepresentation()
        let startCastles = game.boardState.castlesAvailable
        let move = game.boardState.currentValidMoves.first { moveToNotation(move: $0) == "e2e4" }
        #expect(move != nil)
        game.play(move!)
        #expect(game.boardState.currentTurnColor == .black)
        #expect(game.toBoardArrayRepresentation() != startBoard)
        game.unplay()
        #expect(game.boardState.currentTurnColor == .white)
        #expect(game.toBoardArrayRepresentation() == startBoard)
        #expect(game.boardState.castlesAvailable == startCastles)
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func playUnplayRestoresCastle() {
        let game = Game()
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let startBoard = game.toBoardArrayRepresentation()
        let castle = game.findMove(notation: "e1g1")!
        game.play(castle)
        game.unplay()
        #expect(game.toBoardArrayRepresentation() == startBoard)
        #expect(game.boardState.currentTurnColor == .white)
        #expect(game.findMove(notation: "e1g1") != nil)
    }
    
    @Test func clockSearchSubtractsMoveOverhead() {
        let go = UciGoInput.parse(from: "go wtime 60000 btime 60000")
        let limits = SearchLimits.from(go: go, sideToMove: .white, moveOverheadMs: 2000)
        #expect(limits.allocatedTime != nil)
        #expect(limits.allocatedTime! < 30.0)
    }
}
