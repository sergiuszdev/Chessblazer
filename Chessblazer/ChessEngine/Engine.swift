//
//  Engine.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

class Engine {
    let engineName = "Chessblazer"
    let engineVersion = "alpha 0.001"
    var quit = false
    let engineAuthor = "sergiusz"
    
    var game = Game()
    
    func processInput(command input: String) {
        let args = input.components(separatedBy: .whitespaces)
        guard let command = CommandsGUItoEngine(rawValue: args[0]) else { return }

        switch command {
        case .uci:
            sendOutput(output: "id name \(engineName)")
            sendOutput(output: "id author \(engineAuthor)")
            sendOutput(output: "uciok")
        case .isready:
            sendOutput(output: "readyok")
        case .ucinewgame:
            game.startNewGame()
            
        case .position:
            if args[1] == "fen" {
                game.loadFromFen(fen: args[2])
            } else if args[1] == "startpos" {
                game.startNewGame()
                if args.indices.contains(2), args[2] == "moves" {
                    let moves = args[3..<args.count]
                    for move in moves {
                        game.makeMove(move: game.findMove(notation: move))
                    }
                }
            }

        case .go:
            let bestMove = game.boardState.currentTurnColor == .white
                ? findBestMove(game: game, depth: 3, maximizingPlayer: true)
                : findBestMove(game: game, depth: 3, maximizingPlayer: false)
            if let move = bestMove {
                print("bestmove \(moveToNotation(move: move))")
            }
            // so go for dsl regex to capture all possible params and then handle it
            // if no depth then lets say depth = 50 and make it async so you can send signal to stop with .stop
            
            
        case .stop:
            // here should be sent signal to stop searching for best move
            
            print("")
        
        case .quit:
            quit = true
        
        case .eve:
            let game = Game()
            game.startNewGame()
            let bp = BoardPrinter()
            bp.printBoard(board: game.toBoardArrayRepresentation())

            while !game.boardData.hasGameEnded {
                let bestMove = game.boardState.currentTurnColor == .white
                    ? findBestMove(game: game, depth: 3, maximizingPlayer: true)
                    : findBestMove(game: game, depth: 3, maximizingPlayer: false)
                
                game.makeMove(move: bestMove!)
                bp.printBoard(board: game.toBoardArrayRepresentation())
            }

        default:
            return
        }
    }

    func sendOutput(output: String) {
        print(output)
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
