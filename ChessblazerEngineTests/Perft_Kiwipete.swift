//
//  Perft_Kiwipete.swift
//  ChessblazerEngineTests
//
//  Created by sergiusz on 29/01/2025.
//

import Testing
#if SWIFT_PACKAGE
@testable import Chessblazer
#endif

@Suite("Perft tests // Kiwipete")
struct Perft_Kiwipete {
    
    @Test(arguments: [
        (depth: 1, expectedNodes: 48),
        (depth: 2, expectedNodes: 2039),
        (depth: 3, expectedNodes: 97862),
        (depth: 4, expectedNodes: 4085603),
        (depth: 5, expectedNodes: 193690690),
    ])
    func testNodes(depth: Int, expectedNodes: Int) async throws {
        let timer = ContinuousClock().now
        let result = bulkPerftTest(depth: depth, fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let elapsedTime = timer.duration(to: .now)
        #expect(result == expectedNodes)
        print("Depth \(depth)" + ": \(elapsedTime) seconds")
        
    }

    @Test(arguments: [
        (depth: 1, expectedNodes: 48, expectedData: PerftData(captures: 8, enPassants: 0, castles: 2, checks: 0, checkmates: 0, promotions: 0)),
        (depth: 2, expectedNodes: 2039, expectedData: PerftData(captures: 351, enPassants: 1, castles: 91, checks: 3, checkmates: 0, promotions: 0)),
        (depth: 3, expectedNodes: 97862, expectedData: PerftData(captures: 17102, enPassants: 45, castles: 3162, checks: 993, checkmates: 1, promotions: 0)),
        (depth: 4, expectedNodes: 4085603, expectedData: PerftData(captures: 757163, enPassants: 1929, castles: 128013, checks: 25523, checkmates: 43, promotions: 15172)),
    ])
    func testDetails(depth: Int, expectedNodes: Int, expectedData: PerftData) async throws {
        let timer = ContinuousClock().now
        let result = perftTest(depth: depth, fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        let elapsedTime = timer.duration(to: .now)
        #expect(result.0 == expectedNodes && result.1 == expectedData)
        print("[Detailed] Depth \(depth)" + ": \(elapsedTime) seconds")
    }
}
