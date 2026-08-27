import Testing
import Foundation
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("Opening book")
struct OpeningBookTests {
    @Test func startposPolyglotKeyMatchesSpec() {
        let game = Game()
        #expect(Polyglot.hash(game.boardState) == Polyglot.startposKey)
        #expect(Polyglot.hash(game.boardState) != game.boardState.zobristKey)
    }
    
    @Test func specKeysAfterQuietAndEnPassantMoves() {
        let sequences: [(moves: [String], key: UInt64)] = [
            (["e2e4"], 0x823C9B50FD114196),
            (["e2e4", "d7d5"], 0x0756B94461C50FB0),
            (["e2e4", "d7d5", "e4e5"], 0x662FAFB965DB29D4),
            (["e2e4", "d7d5", "e4e5", "f7f5"], 0x22A48B5A8E47FF78),
            (["e2e4", "d7d5", "e4e5", "f7f5", "e1e2"], 0x652A607CA3F242C1),
            (["e2e4", "d7d5", "e4e5", "f7f5", "e1e2", "e8f7"], 0x00FDD303C946BDD9),
            (["a2a4", "b7b5", "h2h4", "b5b4", "c2c4"], 0x3C8123EA7B067637),
            (["a2a4", "b7b5", "h2h4", "b5b4", "c2c4", "b4c3", "a1a3"], 0x5C3F9B829B279560),
        ]
        for (moves, key) in sequences {
            let game = Game()
            play(moves, on: game)
            #expect(Polyglot.hash(game.boardState) == key, "after \(moves.joined(separator: " "))")
        }
    }
    
    @Test func fenWithUncapturableEnPassantMatchesPlayedE4() {
        let played = Game()
        play(["e2e4"], on: played)
        let fromFen = Game()
        fromFen.loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
        #expect(Polyglot.hash(played.boardState) == Polyglot.hash(fromFen.boardState))
        #expect(Polyglot.hash(fromFen.boardState) == 0x823C9B50FD114196)
    }
    
    @Test func decodesPolyglotCastleAsUciKingDestination() {
        let game = Game()
        game.loadFromFen(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let raw = Polyglot.encodeMove(from: 4, to: 7)
        let move = Polyglot.decodeMove(
            raw,
            legalMoves: game.boardState.currentValidMoves,
            bitboards: game.boardState.bitboards
        )
        #expect(move != nil)
        #expect(move?.castling == true)
        #expect(moveToNotation(move: move!) == "e1g1")
    }
    
    @Test func bookPicksWeightedMoveFromGeneratedBin() {
        let game = Game()
        let key = Polyglot.hash(game.boardState)
        let e2e4 = Polyglot.encodeMove(from: 12, to: 28)
        let d2d4 = Polyglot.encodeMove(from: 11, to: 27)
        let data = Polyglot.makeBookData(entries: [
            PolyglotEntry(key: key, rawMove: e2e4, weight: 90, learn: 0),
            PolyglotEntry(key: key, rawMove: d2d4, weight: 10, learn: 0),
        ])
        let book = PolyglotBook(data: data)
        #expect(book != nil)
        let move = book!.chooseMove(boardState: game.boardState, variety: false)
        #expect(moveToNotation(move: move!) == "e2e4")
    }
    
    @Test func bookIgnoresMovesThatAreNotLegal() {
        let game = Game()
        let key = Polyglot.hash(game.boardState)
        let fake = Polyglot.encodeMove(from: 0, to: 8)
        let data = Polyglot.makeBookData(entries: [
            PolyglotEntry(key: key, rawMove: fake, weight: 1, learn: 0),
        ])
        let book = PolyglotBook(data: data)!
        #expect(book.chooseMove(boardState: game.boardState, variety: false) == nil)
    }
    
    @Test func uciAdvertisesBookOptions() {
        let names = EngineUciOptions.advertised.map(\.name)
        #expect(names.contains("OwnBook"))
        #expect(names.contains("Book File"))
        #expect(names.contains("Book Variety"))
        
        var options = EngineUciOptions()
        #expect(options.ownBook)
        #expect(options.bookFile == "")
        #expect(options.bookVariety)
        options.set(name: "OwnBook", value: "false")
        options.set(name: "Book File", value: "Books/final-book.bin")
        options.set(name: "Book Variety", value: "false")
        #expect(!options.ownBook)
        #expect(options.bookFile == "Books/final-book.bin")
        #expect(!options.bookVariety)
    }
    
    @Test func loadsBookFromPathAndProbesStartpos() throws {
        let game = Game()
        let key = Polyglot.hash(game.boardState)
        let e2e4 = Polyglot.encodeMove(from: 12, to: 28)
        let data = Polyglot.makeBookData(entries: [
            PolyglotEntry(key: key, rawMove: e2e4, weight: 1, learn: 0),
        ])
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("chessblazer-test-book.bin")
        try data.write(to: url)
        let book = PolyglotBook(path: url.path)
        #expect(book != nil)
        #expect(moveToNotation(move: book!.chooseMove(boardState: game.boardState, variety: false)!) == "e2e4")
        try? FileManager.default.removeItem(at: url)
    }
    
    private func play(_ notations: [String], on game: Game) {
        for notation in notations {
            let move = game.findMove(notation: notation)
            #expect(move != nil, "expected legal move \(notation)")
            game.makeMove(move: move!)
        }
    }
}
