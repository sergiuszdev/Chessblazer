//
//  Perf.swift
//  Chessblazer
//
//  Created by sergiusz on 05/09/2024.
//

import Foundation

struct PerftData : Equatable {
    var captures: Int = 0
    var enPassants: Int = 0
    var castles: Int = 0
    var checks: Int = 0
    var checkmates: Int = 0
    var promotions: Int = 0
    
    static func ==(lhs: PerftData, rhs: PerftData) -> Bool {
        return lhs.captures == rhs.captures
            && lhs.castles == rhs.castles
            && lhs.checks == rhs.checks
            && lhs.checkmates == rhs.checkmates
            && lhs.enPassants == rhs.enPassants
            && lhs.promotions == rhs.promotions
    }
}

func perftTest(depth: Int) -> (Int, PerftData) {
    perftTest(depth: depth, fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
}

func perftTest(depth: Int, fen: String) -> (Int, PerftData) {
    var perftData = PerftData()
    let game = Game()
    game.loadFromFen(fen: fen)
    
    func perft(depth: Int) -> Int {
        let moves = generateAllLegalMoves(boardState: game.boardState)
        if depth == 1 {
            for move in moves {
                if move.castling {
                    perftData.castles += 1
                }
                if move.promotionPiece != 0 {
                    perftData.promotions += 1
                }
                if move.captureValue != 0 && !move.castling {
                    perftData.captures += 1
                }
                if move.enPasssantCapture != 0 {
                    perftData.enPassants += 1
                }
                
                game.play(move)
                if checkIfCheck(boardState: game.boardState) {
                    perftData.checks += 1
                    if generateAllLegalMoves(boardState: game.boardState).isEmpty {
                        perftData.checkmates += 1
                    }
                }
                game.unplay()
            }
            return moves.count
        }
        
        var nodeCount = 0
        for move in moves {
            game.play(move)
            nodeCount += perft(depth: depth - 1)
            game.unplay()
        }
        return nodeCount
    }
    
    return (perft(depth: depth), perftData)
}

func bulkPerftTest(depth: Int) -> Int {
    bulkPerftTest(depth: depth, fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
}

func bulkPerftTest(depth: Int, fen: String) -> Int {
    let game = Game()
    game.loadFromFen(fen: fen)
    
    func perft(depth: Int) -> Int {
        let moves = generateAllLegalMoves(boardState: game.boardState)
        if depth == 1 {
            return moves.count
        }
        
        var nodeCount = 0
        for move in moves {
            game.play(move)
            nodeCount += perft(depth: depth - 1)
            game.unplay()
        }
        return nodeCount
    }
    return perft(depth: depth)
}
