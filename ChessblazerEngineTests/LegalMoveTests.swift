import Testing

@Suite("Legal generation")
struct LegalMoveTests {
    @Test func startposHasTwentyMoves() {
        let game = Game()
        #expect(game.boardState.currentValidMoves.count == 20)
    }
    
    @Test func pinnedKnightCannotLeaveTheRay() {
        let game = Game()
        game.loadFromFen(fen: "4r3/8/8/8/8/8/4N3/4K3 w - - 0 1")
        let notations = Set(game.boardState.currentValidMoves.map(moveToNotation))
        #expect(!notations.contains("e2c1"))
        #expect(!notations.contains("e2c3"))
        #expect(!notations.contains("e2d4"))
        #expect(!notations.contains("e2f4"))
        #expect(!notations.contains("e2g3"))
        #expect(!notations.contains("e2g1"))
    }
    
    @Test func kingCannotCaptureAProtectedPiece() {
        let game = Game()
        game.loadFromFen(fen: "8/8/4k3/4p3/4K3/8/8/8 w - - 0 1")
        let notations = Set(game.boardState.currentValidMoves.map(moveToNotation))
        #expect(!notations.contains("e4e5"))
        #expect(notations.contains("e4d3") || notations.contains("e4f3") || notations.contains("e4d4"))
    }
    
    @Test func enPassantThatOpensARankCheckIsIllegal() {
        let game = Game()
        game.loadFromFen(fen: "8/8/8/K2pP2r/8/8/8/8 w - - 0 1")
        game.boardState.lastMove = Move(
            fromSquare: 51,
            targetSquare: 35,
            pieceValue: Piece.ColoredPieces.blackPawn.rawValue,
            captureValue: 0
        )
        game.boardState.currentValidMoves = generateAllLegalMoves(boardState: game.boardState)
        let notations = Set(game.boardState.currentValidMoves.map(moveToNotation))
        #expect(!notations.contains("e5d6"))
    }
    
    @Test func enPassantCanCaptureACheckingPawn() {
        let game = Game()
        game.loadFromFen(fen: "8/8/8/2k5/3Pp3/8/8/4K3 b - - 0 1")
        game.boardState.lastMove = Move(
            fromSquare: 11,
            targetSquare: 27,
            pieceValue: Piece.ColoredPieces.whitePawn.rawValue,
            captureValue: 0
        )
        game.boardState.currentValidMoves = generateAllLegalMoves(boardState: game.boardState)
        let notations = Set(game.boardState.currentValidMoves.map(moveToNotation))
        #expect(notations.contains("e4d3"))
    }
    
    @Test func doubleCheckAllowsOnlyKingMoves() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/4r3/r3K3 w - - 0 1")
        let moves = game.boardState.currentValidMoves
        #expect(!moves.isEmpty)
        #expect(moves.allSatisfy { Piece.getType(piece: $0.pieceValue) == .king })
    }
    
    @Test func kiwipeteDepthOne() {
        let game = Game()
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        #expect(game.boardState.currentValidMoves.count == 48)
    }
    
    @Test func blackKingOnH8DoesNotTrap() {
        let h8Attacks = generateBlackPawnAttacks(square: 63)
        #expect(h8Attacks == generateBlackPawnAttacks(blackPawns: Bitboard.bit(at: 63)))
        
        let game = Game()
        game.loadFromFen(fen: "7k/8/8/8/8/8/8/7K b - - 0 1")
        #expect(!game.boardState.currentValidMoves.isEmpty)
        let move = findBestMove(game: game, depth: 4, maximizingPlayer: false)
        #expect(move != nil)
        #expect(game.boardState.currentValidMoves.contains(move!))
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func betweenSquaresOnAFile() {
        let e1 = 4
        let e8 = 60
        var expected: Bitboard = 0
        for rank in 1...6 {
            expected |= Bitboard(1) << Bitboard(rank * 8 + 4)
        }
        #expect(Rays.between[e1][e8] == expected)
        #expect(Rays.between[e1][e1] == 0)
        #expect(Rays.between[e1][5] == 0)
    }
}
