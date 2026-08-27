import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("Syzygy")
struct SyzygyTests {
    @Test func emptyPathDisablesTables() {
        Syzygy.setPath("")
        #expect(!Syzygy.isReady)
        #expect(Syzygy.maxPieces == 0)
        
        let game = Game()
        game.loadFromFen(fen: "8/8/8/4k3/8/8/8/4K3 w - - 0 1")
        #expect(Syzygy.probeWDL(game.boardState) == nil)
        #expect(Syzygy.probeRootMove(game.boardState) == nil)
    }
    
    @Test func missingDirectoryLeavesTablesDisabled() {
        Syzygy.setPath("/tmp/chessblazer-syzygy-does-not-exist-\(UUID().uuidString)")
        #expect(!Syzygy.isReady)
        Syzygy.setPath("")
    }
    
    @Test func setOptionParsesSyzygyPath() {
        var options = EngineUciOptions()
        options.set(name: "SyzygyPath", value: "/path/to/syzygy")
        #expect(options.syzygyPath == "/path/to/syzygy")
        
        let advertised = EngineUciOptions.advertised.map(\.name)
        #expect(advertised.contains("SyzygyPath"))
    }
    
    @Test func pieceCountMatchesOccupancy() {
        let game = Game()
        game.loadFromFen(fen: "8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1")
        #expect(Syzygy.pieceCount(bitboards: game.boardState.bitboards) == 3)
    }
    
    @Test func wdlScoreIsWhiteRelative() {
        let winWhite = Syzygy.score(wdl: .win, whiteToMove: true, ply: 2)
        let winBlack = Syzygy.score(wdl: .win, whiteToMove: false, ply: 2)
        #expect(winWhite == Syzygy.tablebaseWin - 2)
        #expect(winBlack == -(Syzygy.tablebaseWin - 2))
        #expect(Syzygy.score(wdl: .cursedWin, whiteToMove: true, ply: 0) == 0)
        #expect(Syzygy.score(wdl: .blessedLoss, whiteToMove: true, ply: 0) == 0)
    }
    
    @Test func castlingRightsSkipProbe() {
        Syzygy.setPath("")
        let game = Game()
        game.loadFromFen(fen: "4k3/8/8/8/8/8/8/R3K3 w Q - 0 1")
        #expect(!game.boardState.castlesAvailable.isEmpty)
        #expect(Syzygy.probeWDL(game.boardState) == nil)
        #expect(Syzygy.probeRootMove(game.boardState) == nil)
    }
    
    @Test func nonZeroHalfmoveSkipsWdlProbe() {
        Syzygy.setPath("")
        let game = Game()
        game.loadFromFen(fen: "8/8/8/4k3/8/8/8/4KQ2 w - - 12 1")
        #expect(game.boardState.halfmoveClock == 12)
        #expect(Syzygy.probeWDL(game.boardState) == nil)
    }
}
