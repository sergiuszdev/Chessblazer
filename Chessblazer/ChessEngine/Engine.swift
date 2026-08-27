//
//  Engine.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

public final class Engine: @unchecked Sendable {
    public let engineName = "Chessblazer"
    public let engineVersion = "alpha 0.002"
    public var quit = false
    public let engineAuthor = "sergiusz"
    
    public var game = Game()
    private var uciOptions = EngineUciOptions()
    private let transpositionTable = TranspositionTable(megabytes: 16)
    private var openingBook: PolyglotBook?
    
    private let outputLock = NSLock()
    private let flagLock = NSLock()
    private var stopSearch = false
    private let searchGroup = DispatchGroup()
    private static let searchStackSize = 8 * 1024 * 1024
    
    public init() {}
    
    public func processInput(command input: String) {
        let args = input.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard let token = args.first, let command = CommandsGUItoEngine(rawValue: token) else { return }

        switch command {
        case .uci:
            sendOutput(output: "id name \(engineName) \(engineVersion)")
            sendOutput(output: "id author \(engineAuthor)")
            for option in EngineUciOptions.advertised {
                sendOutput(output: option.advertisement)
            }
            sendOutput(output: "uciok")
        case .setoption:
            if let parsed = parseUciSetOption(args: args) {
                uciOptions.set(name: parsed.name, value: parsed.value)
                if parsed.name.lowercased() == "book file" {
                    reloadOpeningBook()
                } else if parsed.name.lowercased() == "syzygypath" {
                    reloadSyzygy()
                }
            }
        case .isready:
            sendOutput(output: "readyok")
        case .ucinewgame:
            haltSearch()
            transpositionTable.clear()
            PawnEvalCache.clear()
            game.startNewGame()
            
        case .position:
            haltSearch()
            applyPosition(args: args)

        case .go:
            haltSearch()
            let go = UciGoInput.parse(from: input)
            if !go.infinite, let bookMove = probeOpeningBook() {
                sendOutput(output: "bestmove \(moveToNotation(move: bookMove))")
                return
            }
            if !go.infinite, let tbMove = Syzygy.probeRootMove(game.boardState) {
                sendOutput(output: "info string syzygy hit")
                sendOutput(output: "bestmove \(moveToNotation(move: tbMove))")
                return
            }
            let limits = SearchLimits.from(
                go: go,
                sideToMove: game.boardState.currentTurnColor,
                moveOverheadMs: uciOptions.moveOverheadMs
            )
            startSearch(limits: limits)
            
        case .stop:
            requestStop()
            
        case .ponderhit:
            break
        
        case .quit:
            haltSearch()
            quit = true
        
        case .eve:
            haltSearch()
            let game = Game()
            game.startNewGame()
            let bp = BoardPrinter()
            bp.printBoard(board: game.toBoardArrayRepresentation())

            while !game.boardData.hasGameEnded {
                let maximizingPlayer = game.boardState.currentTurnColor == .white
                let limits = SearchLimits(maxDepth: 4, allocatedTime: 1.0)
                guard let bestMove = findBestMove(game: game, limits: limits, maximizingPlayer: maximizingPlayer) else {
                    break
                }
                game.makeMove(move: bestMove)
                bp.printBoard(board: game.toBoardArrayRepresentation())
            }

        default:
            return
        }
    }
    
    private func startSearch(limits: SearchLimits) {
        setStopSearch(false)
        let maximizingPlayer = game.boardState.currentTurnColor == .white
        let rootMoves = game.boardState.currentValidMoves
        let threadCount = uciOptions.threadCount
        transpositionTable.resize(megabytes: uciOptions.hashSizeMB)
        transpositionTable.newSearch()
        
        // Helpers fill the shared TT; only the main thread emits info / bestmove.
        // Syzygy DTZ already ran on the UCI thread before startSearch.
        for helperIndex in 1..<threadCount {
            searchGroup.enter()
            let helperGame = Game.copyForSearch(from: game)
            let helperLimits = SearchLimits(
                maxDepth: limits.maxDepth,
                allocatedTime: limits.allocatedTime,
                hardTime: limits.hardTime
            )
            let thread = Thread { [self] in
                defer { self.searchGroup.leave() }
                _ = findBestMove(
                    game: helperGame,
                    limits: helperLimits,
                    maximizingPlayer: maximizingPlayer,
                    isCancelled: { self.isStopRequested() },
                    onInfo: nil,
                    tt: self.transpositionTable,
                    beginNewSearch: false
                )
            }
            thread.stackSize = Self.searchStackSize
            thread.name = "chessblazer.helper.\(helperIndex)"
            thread.qualityOfService = .userInitiated
            thread.start()
        }
        
        searchGroup.enter()
        let main = Thread { [self] in
            defer { self.searchGroup.leave() }
            let move = findBestMove(
                game: self.game,
                limits: limits,
                maximizingPlayer: maximizingPlayer,
                isCancelled: { self.isStopRequested() },
                onInfo: { self.sendOutput(output: $0) },
                tt: self.transpositionTable,
                beginNewSearch: false
            )
            self.requestStop()
            let chosen: Move?
            if let move, rootMoves.contains(move) {
                chosen = move
            } else {
                chosen = rootMoves.first
            }
            if let chosen {
                self.sendOutput(output: "bestmove \(moveToNotation(move: chosen))")
            } else {
                self.sendOutput(output: "bestmove 0000")
            }
        }
        main.stackSize = Self.searchStackSize
        main.name = "chessblazer.search"
        main.qualityOfService = .userInitiated
        main.start()
    }
    
    private func requestStop() {
        setStopSearch(true)
    }
    
    private func haltSearch() {
        requestStop()
        searchGroup.wait()
    }
    
    private func setStopSearch(_ value: Bool) {
        flagLock.lock()
        stopSearch = value
        flagLock.unlock()
    }
    
    private func isStopRequested() -> Bool {
        flagLock.lock()
        defer { flagLock.unlock() }
        return stopSearch
    }
    
    private func reloadOpeningBook() {
        let path = uciOptions.bookFile.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.isEmpty {
            openingBook = nil
            return
        }
        openingBook = PolyglotBook(path: path)
        if openingBook == nil {
            sendOutput(output: "info string failed to load opening book \(path)")
        }
    }
    
    private func reloadSyzygy() {
        let path = uciOptions.syzygyPath
        Syzygy.setPath(path)
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sendOutput(output: "info string syzygy disabled")
        } else if Syzygy.isReady {
            sendOutput(output: "info string syzygy found \(Syzygy.maxPieces)-piece tables")
        } else {
            sendOutput(output: "info string syzygy path set but no tables found")
        }
    }
    
    private func probeOpeningBook() -> Move? {
        guard uciOptions.ownBook, let book = openingBook else { return nil }
        guard let move = book.chooseMove(boardState: game.boardState, variety: uciOptions.bookVariety) else {
            return nil
        }
        guard game.boardState.currentValidMoves.contains(move) else { return nil }
        return move
    }
    
    private func applyPosition(args: [String]) {
        guard args.count >= 2 else { return }
        let movesIndex = args.firstIndex(of: "moves")
        
        if args[1] == "fen" {
            let fenEnd = movesIndex ?? args.count
            guard fenEnd > 2 else { return }
            let fen = args[2..<fenEnd].joined(separator: " ")
            game.loadFromFen(fen: fen)
        } else if args[1] == "startpos" {
            game.startNewGame()
        } else {
            return
        }
        
        if let movesIndex, movesIndex + 1 < args.count {
            for notation in args[(movesIndex + 1)...] {
                if let move = game.findMove(notation: notation) {
                    game.makeMove(move: move)
                } else {
                    sendOutput(output: "info string unknown move \(notation)")
                }
            }
        }
    }

    func sendOutput(output: String) {
        outputLock.lock()
        print(output)
        fflush(stdout)
        outputLock.unlock()
    }
}

enum CommandsGUItoEngine: String {
    case uci
    case debug
    case isready
    case setoption
    case register
    case ucinewgame
    case position
    case go
    case stop
    case ponderhit
    case quit
    case pve
    case eve
}
