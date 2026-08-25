import Testing

@Suite("Eval")
struct EvalTests {
    @Test func startposIsFullMiddlegamePhase() {
        let game = Game()
        #expect(GamePhase.of(game.boardState.bitboards) == GamePhase.full)
    }
    
    @Test func kingsOnlyIsEndgamePhase() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1")
        #expect(GamePhase.of(game.boardState.bitboards) == 0)
    }
    
    @Test func kingPstInterpolatesWithPhase() {
        let e1 = 4
        let whiteKing = Piece.ColoredPieces.whiteKing.rawValue
        let middlegame = PieceSquareTables.pieceSquareValue(piece: whiteKing, square: e1, phase: GamePhase.full)
        let endgame = PieceSquareTables.pieceSquareValue(piece: whiteKing, square: e1, phase: 0)
        let mid = PieceSquareTables.pieceSquareValue(piece: whiteKing, square: e1, phase: GamePhase.full / 2)
        
        #expect(middlegame == PieceSquareTables.kingMidgameTable[e1])
        #expect(endgame == PieceSquareTables.kingEndgameTable[e1])
        #expect(mid == GamePhase.interpolate(middlegame: middlegame, endgame: endgame, phase: 12))
        #expect(endgame > middlegame)
    }
    
    @Test func openingPrefersKingOnBackRankOverCenter() {
        let whiteKing = Piece.ColoredPieces.whiteKing.rawValue
        let e1 = PieceSquareTables.pieceSquareValue(piece: whiteKing, square: 4, phase: GamePhase.full)
        let e4 = PieceSquareTables.pieceSquareValue(piece: whiteKing, square: 28, phase: GamePhase.full)
        #expect(e1 > e4)
    }
    
    @Test func endgamePrefersActiveKing() {
        let back = Game()
        back.loadFromFen(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1")
        let center = Game()
        center.loadFromFen(fen: "4k3/8/8/8/4K3/8/8/8 w - - 0 1")
        #expect(evaluate(bitboards: center.boardState.bitboards) > evaluate(bitboards: back.boardState.bitboards))
    }
    
    @Test func pawnsDoNotAffectPhase() {
        let kings = Game()
        kings.loadFromFen(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1")
        let withPawns = Game()
        withPawns.loadFromFen(fen: "4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1")
        #expect(GamePhase.of(kings.boardState.bitboards) == GamePhase.of(withPawns.boardState.bitboards))
    }
    
    @Test func startposIsRoughlyEqual() {
        let game = Game()
        #expect(abs(evaluate(bitboards: game.boardState.bitboards)) < 20)
    }
    
    @Test func connectedPawnsBeatIsolated() {
        let connected = Game()
        connected.loadFromFen(fen: "4k3/8/8/8/8/8/PP6/4K3 w - - 0 1")
        let isolated = Game()
        isolated.loadFromFen(fen: "4k3/8/8/8/8/8/P1P5/4K3 w - - 0 1")
        #expect(
            evaluate(bitboards: connected.boardState.bitboards)
                > evaluate(bitboards: isolated.boardState.bitboards)
        )
    }
    
    @Test func connectedPawnsBeatDoubled() {
        let connected = Game()
        connected.loadFromFen(fen: "4k3/8/8/8/8/8/PP6/4K3 w - - 0 1")
        let doubled = Game()
        doubled.loadFromFen(fen: "4k3/8/8/8/8/P7/P7/4K3 w - - 0 1")
        #expect(
            evaluate(bitboards: connected.boardState.bitboards)
                > evaluate(bitboards: doubled.boardState.bitboards)
        )
    }
    
    @Test func passedPawnIsAnAsset() {
        let passed = Game()
        passed.loadFromFen(fen: "4k3/8/8/P7/8/8/8/4K3 w - - 0 1")
        let blocked = Game()
        blocked.loadFromFen(fen: "4k3/1p6/8/P7/8/8/8/4K3 w - - 0 1")
        #expect(
            evaluate(bitboards: passed.boardState.bitboards)
                > evaluate(bitboards: blocked.boardState.bitboards)
        )
    }
    
    @Test func centralKnightHasMoreMobility() {
        let central = Game()
        central.loadFromFen(fen: "4k3/8/8/8/4N3/8/8/4K3 w - - 0 1")
        let corner = Game()
        corner.loadFromFen(fen: "4k3/8/8/8/8/8/8/N3K3 w - - 0 1")
        #expect(
            evaluate(bitboards: central.boardState.bitboards)
                > evaluate(bitboards: corner.boardState.bitboards)
        )
    }
    
    @Test func pawnShieldHelpsAgainstAQueen() {
        let shielded = Game()
        shielded.loadFromFen(fen: "3qk3/8/8/8/8/8/3PPP2/4K3 w - - 0 1")
        let exposed = Game()
        exposed.loadFromFen(fen: "3qk3/8/8/8/8/8/PPP5/4K3 w - - 0 1")
        #expect(
            evaluate(bitboards: shielded.boardState.bitboards)
                > evaluate(bitboards: exposed.boardState.bitboards)
        )
    }
}
