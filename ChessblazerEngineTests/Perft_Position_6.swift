//
//  Perft_Position_6.swift
//  ChessblazerEngineTests
//
//  Created by sergiusz on 26/08/2026.
//

import Testing

@Suite("Perft tests // Position 6")
struct Perft_Position_6 {
    
    @Test(arguments: [
        (depth: 1, expectedNodes: 46),
        (depth: 2, expectedNodes: 2079),
        (depth: 3, expectedNodes: 89890),
        (depth: 4, expectedNodes: 3894594),
    ])
    func testNodes(depth: Int, expectedNodes: Int) async throws {
        let timer = ContinuousClock().now
        let result = bulkPerftTest(depth: depth, fen: "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10")
        let elapsedTime = timer.duration(to: .now)
        #expect(result == expectedNodes)
        print("Depth \(depth)" + ": \(elapsedTime) seconds")
        
    }
}
