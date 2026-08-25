//
//  MagicGeneration.swift
//  Chessblazer
//
//  Created by sergiusz on 06/09/2024.
//

import Foundation

func magicIndex(magic: UInt64, shift: Int, blocker: Bitboard) -> UInt64 {
    let hash = blocker.multipliedReportingOverflow(by: magic)
    return hash.0 >> shift
}
