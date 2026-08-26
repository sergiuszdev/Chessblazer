//
//  MagicGeneration.swift
//  Chessblazer
//
//  Created by sergiusz on 06/09/2024.
//

import Foundation

func magicIndex(magic: UInt64, shift: Int, blocker: Bitboard) -> Int {
    let hash = blocker.multipliedReportingOverflow(by: magic)
    return Int(hash.0 >> shift)
}

func magicTableCount(shift: Int) -> Int {
    1 << (64 - shift)
}
