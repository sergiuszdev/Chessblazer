//
//  Perft_Position_5.swift
//  ChessblazerEngineTests
//
//  Created by sergiusz on 26/08/2026.
//

import Testing

@Suite("Perft tests // Position 5")
struct Perft_Position_5 {
    
    @Test(arguments: [
        (depth: 1, expectedNodes: 44),
        (depth: 2, expectedNodes: 1486),
        (depth: 3, expectedNodes: 62379),
        (depth: 4, expectedNodes: 2103487),
        (depth: 5, expectedNodes: 89941194),
    ])
    func testNodes(depth: Int, expectedNodes: Int) async throws {
        let timer = ContinuousClock().now
        let result = bulkPerftTest(depth: depth, fen: "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8")
        let elapsedTime = timer.duration(to: .now)
        #expect(result == expectedNodes)
        print("Depth \(depth)" + ": \(elapsedTime) seconds")
        
    }
}
