//
//  Perft_Position_4.swift
//  ChessblazerEngineTests
//
//  Created by sergiusz on 29/01/2025.
//

import Testing

@Suite("Perft tests // Position 4")
struct Perft_Position_4 {
    
    @Test(arguments: [
        (depth: 1, expectedNodes: 6),
        (depth: 2, expectedNodes: 264),
        (depth: 3, expectedNodes: 9467),
        (depth: 4, expectedNodes: 422333),
        (depth: 5, expectedNodes: 15833292),
    ])
    func testNodes(depth: Int, expectedNodes: Int) async throws {
        let timer = ContinuousClock().now
        let result = bulkPerftTest(depth: depth, fen: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1")
        let elapsedTime = timer.duration(to: .now)
        #expect(result == expectedNodes)
        print("Depth \(depth)" + ": \(elapsedTime) seconds")
        
    }

    @Test(arguments: [
        (depth: 1, expectedNodes: 6, expectedData: PerftData(captures: 0, enPassants: 0, castles: 0, checks: 0, checkmates: 0, promotions: 0)),
        (depth: 2, expectedNodes: 264, expectedData: PerftData(captures: 87, enPassants: 0, castles: 6, checks: 10, checkmates: 0, promotions: 48)),
        (depth: 3, expectedNodes: 9467, expectedData: PerftData(captures: 1021, enPassants: 4, castles: 0, checks: 38, checkmates: 22, promotions: 120)),
        
        (depth: 4, expectedNodes: 422333, expectedData: PerftData(captures: 131393, enPassants: 0, castles: 7795, checks: 15492, checkmates: 5, promotions: 60032)),
        (depth: 5, expectedNodes: 15833292, expectedData: PerftData(captures: 2046173, enPassants: 6512, castles: 0, checks: 200568, checkmates: 50562, promotions: 329464)),
    ])
    func testDetails(depth: Int, expectedNodes: Int, expectedData: PerftData) async throws {
        let timer = ContinuousClock().now
        let result = perftTest(depth: depth, fen: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1")
        let elapsedTime = timer.duration(to: .now)
        #expect(result.0 == expectedNodes && result.1 == expectedData)
        print("[Detailed] Depth \(depth)" + ": \(elapsedTime) seconds")
    }
}
