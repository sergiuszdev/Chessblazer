//
//  Engine.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

final class Engine: @unchecked Sendable {
    let engineName = "Chessblazer"
    let engineVersion = "alpha 0.001"
    var quit = false
    let engineAuthor = "sergiusz"
    
    var game = Game()
    private var uciOptions = EngineUciOptions()
    
    private let outputLock = NSLock()
    private let flagLock = NSLock()
    private var stopSearch = false
    private let searchQueue = DispatchQueue(label: "chessblazer.search", qos: .userInitiated)
    private let searchGroup = DispatchGroup()
    
    func processInput(command input: String) {
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
        case .isready:
            sendOutput(output: "readyok")
        case .setoption:
            if let parsed = parseUciSetOption(args: args) {
                uciOptions.set(name: parsed.name, value: parsed.value)
            }
        case .ucinewgame:
            haltSearch()
            game.startNewGame()
            
        case .position:
            haltSearch()
            applyPosition(args: args)

        case .go:
            haltSearch()
            let go = UciGoInput.parse(from: input)
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
        searchGroup.enter()
        searchQueue.async {
            defer { self.searchGroup.leave() }
            let move = findBestMove(
                game: self.game,
                limits: limits,
                maximizingPlayer: maximizingPlayer,
                isCancelled: { self.isStopRequested() },
                onInfo: { self.sendOutput(output: $0) }
            )
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
