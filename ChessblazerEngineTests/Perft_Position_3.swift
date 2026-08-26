//
//  Perft_Position_3.swift
//  ChessblazerEngineTests
//
//  Created by sergiusz on 29/01/2025.
//

import Testing

@Suite("Perft tests // Position 3")
struct Perft_Position_3 {
    
    @Test(arguments: [
        (depth: 1, expectedNodes: 14),
        (depth: 2, expectedNodes: 191),
        (depth: 3, expectedNodes: 2812),
        (depth: 4, expectedNodes: 43238),
        (depth: 5, expectedNodes: 674624),
        (depth: 6, expectedNodes: 11030083),
    ])
    func testNodes(depth: Int, expectedNodes: Int) async throws {
        let timer = ContinuousClock().now
        let result = bulkPerftTest(depth: depth, fen: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -")
        let elapsedTime = timer.duration(to: .now)
        #expect(result == expectedNodes)
        print("Depth \(depth)" + ": \(elapsedTime) seconds")
        
    }

    @Test(arguments: [
        (depth: 1, expectedNodes: 14, expectedData: PerftData(captures: 1, enPassants: 0, castles: 0, checks: 2, checkmates: 0, promotions: 0)),
        (depth: 2, expectedNodes: 191, expectedData: PerftData(captures: 14, enPassants: 0, castles: 0, checks: 10, checkmates: 0, promotions: 0)),
        (depth: 3, expectedNodes: 2812, expectedData: PerftData(captures: 209, enPassants: 2, castles: 0, checks: 267, checkmates: 0, promotions: 0)),
        
        (depth: 4, expectedNodes: 43238, expectedData: PerftData(captures: 3348, enPassants: 123, castles: 0, checks: 1680, checkmates: 17, promotions: 0)),
        (depth: 5, expectedNodes: 674624, expectedData: PerftData(captures: 52051, enPassants: 1165, castles: 0, checks: 52950, checkmates: 0, promotions: 0)),
        (depth: 6, expectedNodes: 11030083, expectedData: PerftData(captures: 940350, enPassants: 33325, castles: 0, checks: 452473, checkmates: 2733, promotions: 7552)),
    ])
    func testDetails(depth: Int, expectedNodes: Int, expectedData: PerftData) async throws {
        let timer = ContinuousClock().now
        let result = perftTest(depth: depth, fen: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -")
        let elapsedTime = timer.duration(to: .now)
        #expect(result.0 == expectedNodes && result.1 == expectedData)
        print("[Detailed] Depth \(depth)" + ": \(elapsedTime) seconds")
    }
}
