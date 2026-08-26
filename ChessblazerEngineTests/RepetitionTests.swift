import Testing
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("Repetition")
struct RepetitionTests {
    private let knightReturnToStart = ["g1f3", "b8c6", "f3g1", "c6b8"]
    private let searchCycleBackToNf3Nc6 = ["g1f3", "b8c6", "f3g5", "c6b8", "g5f3", "b8c6"]
    
    @Test func firstRepeatOfStartposIsNotADraw() {
        let game = Game()
        play(knightReturnToStart, on: game)
        #expect(!game.boardState.isRepetitionDraw())
        #expect(game.boardData.gameResult == .none)
        #expect(!game.boardData.hasGameEnded)
        #expect(game.boardState.currentValidMoves.count == 20)
    }
    
    @Test func thirdOccurrenceOfStartposIsADraw() {
        let game = Game()
        play(knightReturnToStart, on: game)
        play(knightReturnToStart, on: game)
        #expect(game.boardState.isRepetitionDraw())
        #expect(game.boardData.hasGameEnded)
        #expect(game.boardData.gameResult == .draw)
    }
    
    @Test func undoLeavesTheSecondOccurrencePlayable() {
        let game = Game()
        play(knightReturnToStart, on: game)
        play(knightReturnToStart, on: game)
        game.undoMove()
        #expect(!game.boardState.isRepetitionDraw())
        #expect(game.boardData.gameResult == .none)
        #expect(!game.boardData.hasGameEnded)
    }
    
    @Test func searchTreatsARepeatAfterTheRootAsADraw() {
        let game = Game()
        play(searchCycleBackToNf3Nc6, on: game)
        #expect(!game.boardState.isRepetitionDraw(ply: 0))
        #expect(game.boardState.isRepetitionDraw(ply: 6))
    }
    
    @Test func repeatingTheRootOnceIsNotASearchDraw() {
        let game = Game()
        play(knightReturnToStart, on: game)
        #expect(!game.boardState.isRepetitionDraw(ply: 4))
    }
    
    @Test func alphabetaScoresThreefoldAsZeroEvenIfTTHasAHit() {
        let game = Game()
        play(knightReturnToStart, on: game)
        play(knightReturnToStart, on: game)
        
        let tt = TranspositionTable(entryCount: 64)
        tt.store(
            key: game.boardState.zobristKey,
            depth: 16,
            score: 12345,
            bound: .exact,
            move: nil
        )
        let context = SearchContext(
            limits: SearchLimits(maxDepth: 4, allocatedTime: nil),
            tt: tt
        )
        let score = alphabeta(
            game: game,
            depth: 4,
            alpha: -MATE_VALUE * 2,
            beta: MATE_VALUE * 2,
            maximizingPlayer: true,
            ply: 0,
            context: context
        )
        #expect(score == 0)
        #expect(game.boardState.undoStack.count == 8)
    }
    
    @Test func nullMoveDoesNotCountAsARepetition() {
        let game = Game()
        game.playNull()
        #expect(!game.boardState.isRepetitionDraw(ply: 1))
        game.unplay()
        play(knightReturnToStart, on: game)
        play(knightReturnToStart, on: game)
        game.playNull()
        #expect(!game.boardState.isRepetitionDraw(ply: 9))
    }
    
    private func play(_ notations: [String], on game: Game) {
        for notation in notations {
            let move = game.findMove(notation: notation)
            #expect(move != nil, "expected legal move \(notation)")
            game.makeMove(move: move!)
        }
    }
}
