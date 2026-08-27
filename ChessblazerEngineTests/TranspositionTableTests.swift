import Testing
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("Transposition table")
struct TranspositionTableTests {
    @Test func storeAndProbeHit() {
        let tt = TranspositionTable(entryCount: 64)
        let move = Move(fromSquare: 12, targetSquare: 28, pieceValue: 0, captureValue: 0)
        tt.store(key: 0xABCD, depth: 6, score: 42, bound: .exact, move: move)
        
        let hit = tt.probe(0xABCD)
        #expect(hit != nil)
        #expect(hit?.score == 42)
        #expect(hit?.depth == 6)
        #expect(hit?.bound == .exact)
        #expect(hit?.move?.fromSquare == 12)
        #expect(hit?.move?.targetSquare == 28)
        #expect(tt.probe(0xDCBA) == nil)
    }
    
    @Test func prefersDeeperEntryOnCollision() {
        let tt = TranspositionTable(entryCount: 2)
        tt.store(key: 2, depth: 8, score: 10, bound: .exact, move: nil)
        tt.store(key: 4, depth: 3, score: 99, bound: .lower, move: nil)
        
        #expect(tt.probe(2)?.depth == 8)
        #expect(tt.probe(2)?.score == 10)
        #expect(tt.probe(4) == nil)
    }
    
    @Test func agedEntryIsReplacedByShallowerCollision() {
        let tt = TranspositionTable(entryCount: 2)
        tt.store(key: 2, depth: 8, score: 10, bound: .exact, move: nil)
        tt.newSearch()
        tt.store(key: 4, depth: 3, score: 99, bound: .lower, move: nil)
        
        #expect(tt.probe(2) == nil)
        #expect(tt.probe(4)?.score == 99)
        #expect(tt.probe(4)?.depth == 3)
    }
    
    @Test func sameKeyAlwaysUpdates() {
        let tt = TranspositionTable(entryCount: 8)
        tt.store(key: 7, depth: 8, score: 10, bound: .exact, move: nil)
        tt.store(key: 7, depth: 2, score: 42, bound: .upper, move: nil)
        #expect(tt.probe(7)?.score == 42)
        #expect(tt.probe(7)?.depth == 2)
        #expect(tt.probe(7)?.bound == .upper)
    }
    
    @Test func clearRemovesEntries() {
        let tt = TranspositionTable(entryCount: 8)
        tt.store(key: 7, depth: 1, score: 1, bound: .exact, move: nil)
        tt.clear()
        #expect(tt.probe(7) == nil)
    }
    
    @Test func mateScoresAdjustByPly() {
        let storedWin = TranspositionTable.scoreToTT(MATE_VALUE - 4, ply: 4)
        #expect(storedWin == MATE_VALUE)
        #expect(TranspositionTable.scoreFromTT(storedWin, ply: 2) == MATE_VALUE - 2)
        
        let storedLoss = TranspositionTable.scoreToTT(-MATE_VALUE + 4, ply: 4)
        #expect(storedLoss == -MATE_VALUE)
        #expect(TranspositionTable.scoreFromTT(storedLoss, ply: 1) == -MATE_VALUE + 1)
    }
    
    @Test func extremeScoresDoNotOverflowWhenAdjusted() {
        #expect(TranspositionTable.scoreToTT(Int.min, ply: 3) == Int.min)
        #expect(TranspositionTable.scoreToTT(Int.max, ply: 3) == Int.max)
        #expect(TranspositionTable.scoreFromTT(Int.min, ply: 3) == Int.min)
        #expect(TranspositionTable.scoreFromTT(Int.max, ply: 3) == Int.max)
    }
    
    @Test func orderMovesPutsHashMoveFirst() {
        let a = Move(fromSquare: 0, targetSquare: 8, pieceValue: 0, captureValue: 0)
        let b = Move(fromSquare: 1, targetSquare: 17, pieceValue: 0, captureValue: 0)
        var moves = [a, b]
        orderMoves(&moves, ttMove: b)
        #expect(moves[0].fromSquare == 1)
        #expect(moves[1].fromSquare == 0)
    }
    
    @Test func searchWithTableStillFindsMateInOne() {
        let game = Game()
        game.loadFromFen(fen: "6k1/8/6K1/8/8/8/8/4R3 w - - 0 1")
        let tt = TranspositionTable(entryCount: 256)
        let move = findBestMove(
            game: game,
            limits: SearchLimits(maxDepth: 2, allocatedTime: nil),
            maximizingPlayer: true,
            tt: tt
        )
        #expect(moveToNotation(move: move!) == "e1e8")
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func deeperSearchStillFindsMateInOne() {
        let game = Game()
        game.loadFromFen(fen: "6k1/8/6K1/8/8/8/8/4R3 w - - 0 1")
        let move = findBestMove(game: game, depth: 4, maximizingPlayer: true)
        #expect(moveToNotation(move: move!) == "e1e8")
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func orderMovesPutsKillerAheadOfOtherQuiets() {
        let quietA = Move(fromSquare: 0, targetSquare: 8, pieceValue: Piece.ColoredPieces.whitePawn.rawValue, captureValue: 0)
        let quietB = Move(fromSquare: 1, targetSquare: 17, pieceValue: Piece.ColoredPieces.whiteKnight.rawValue, captureValue: 0)
        var moves = [quietA, quietB]
        orderMoves(&moves, ttMove: nil, killers: (quietB, nil))
        #expect(moves[0].fromSquare == 1)
    }
    
    @Test func hashOptionResizesTable() {
        var options = EngineUciOptions()
        #expect(options.hashSizeMB == 16)
        options.set(name: "Hash", value: "32")
        #expect(options.hashSizeMB == 32)
        
        let tt = TranspositionTable(megabytes: 1)
        let before = tt.capacity
        tt.resize(megabytes: 2)
        #expect(tt.capacity > before)
        #expect(tt.capacity.nonzeroBitCount == 1)
    }
}
