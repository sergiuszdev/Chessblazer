import Testing
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("SEE and fifty-move")
struct SeeAndFiftyMoveTests {
    @Test func seeWinsUnprotectedQueen() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1")
        let capture = game.findMove(notation: "e4d5")!
        let score = seeScore(
            move: capture,
            bitboards: game.boardState.bitboards,
            occupancy: game.boardState.occupancy,
            sideToMove: .white
        )
        #expect(score == 900)
    }
    
    @Test func seeLosesQueenForPawn() {
        let game = Game()
        game.loadFromFen(fen: "6k1/7p/6p1/8/8/7Q/8/6K1 w - - 0 1")
        let takeH7 = game.findMove(notation: "h3h7")!
        let score = seeScore(
            move: takeH7,
            bitboards: game.boardState.bitboards,
            occupancy: game.boardState.occupancy,
            sideToMove: .white
        )
        #expect(score < 0)
    }
    
    @Test func seeEqualRookRecaptureIsZero() {
        let game = Game()
        game.loadFromFen(fen: "4k3/4r3/8/8/4R3/8/8/4K3 w - - 0 1")
        let capture = game.findMove(notation: "e4e7")!
        let score = seeScore(
            move: capture,
            bitboards: game.boardState.bitboards,
            occupancy: game.boardState.occupancy,
            sideToMove: .white
        )
        #expect(score == 0)
    }
    
    @Test func fiftyMoveFromFenIsADraw() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/8/4K3 w - - 100 50")
        #expect(game.boardState.halfmoveClock == 100)
        #expect(game.boardData.halfMoves == 100)
        #expect(game.boardState.isFiftyMoveDraw(hasLegalMoves: true))
        #expect(game.boardData.gameResult == .draw)
        #expect(game.boardData.hasGameEnded)
    }
    
    @Test func pawnMoveResetsFiftyClock() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/4P3/4K3 w - - 12 10")
        #expect(game.boardState.halfmoveClock == 12)
        game.makeMove(move: game.findMove(notation: "e2e4")!)
        #expect(game.boardState.halfmoveClock == 0)
        #expect(game.boardData.halfMoves == 0)
    }
    
    @Test func quietKingMoveIncrementsFiftyClock() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/8/4K3 w - - 5 10")
        game.makeMove(move: game.findMove(notation: "e1e2")!)
        #expect(game.boardState.halfmoveClock == 6)
        game.undoMove()
        #expect(game.boardState.halfmoveClock == 5)
    }
    
    @Test func mateInOneStillFoundWithSeeAndPruning() {
        let game = Game()
        game.loadFromFen(fen: "6k1/8/6K1/8/8/8/8/4R3 w - - 0 1")
        let move = findBestMove(game: game, depth: 4, maximizingPlayer: true)
        #expect(moveToNotation(move: move!) == "e1e8")
        #expect(game.boardState.undoStack.isEmpty)
    }
    
    @Test func searchDoesNotLeakHalfmove() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/4P3/4K3 w - - 7 10")
        _ = findBestMove(game: game, depth: 3, maximizingPlayer: true)
        #expect(game.boardState.undoStack.isEmpty)
        #expect(game.boardState.halfmoveClock == 7)
    }
    
    @Test func mateIsNotAFiftyMoveDraw() {
        let game = Game()
        game.loadFromFen(fen: "7k/6Q1/6K1/8/8/8/8/8 b - - 100 80")
        #expect(game.boardState.halfmoveClock == 100)
        #expect(game.boardState.currentValidMoves.isEmpty)
        #expect(!game.boardState.isFiftyMoveDraw(hasLegalMoves: false))
        #expect(game.boardData.gameResult == .white)
    }
    
    @Test func captureResetsFiftyClock() {
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/3p4/4P3/8/8/4K3 w - - 40 20")
        game.makeMove(move: game.findMove(notation: "e4d5")!)
        #expect(game.boardState.halfmoveClock == 0)
        #expect(game.boardData.halfMoves == 0)
    }
}
