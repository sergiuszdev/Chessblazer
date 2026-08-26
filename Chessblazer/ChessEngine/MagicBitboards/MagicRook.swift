//
//  MagicRook.swift
//  Chessblazer
//
//  Created by sergiusz on 06/09/2024.
//

import Foundation


let rookShifts: [Int] = [52, 52, 52, 52, 52, 52, 52, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 53, 53, 53, 53, 53, 53, 52, 52, 52, 52, 52, 52, 52, 52, 52]
let rookMagics: [UInt64] = [612489824209895456, 90073229503234056, 72067764789223424, 72075187465756680, 36033195082651648, 4971987182891205890, 288240925673783568, 108087490581165184, 1266637718159648, 2308165188777943042, 2955539331944448, 140806208356356, 140771848225792, 291045332144490497, 14636767517348866, 3504363462530826305, 36187676470149669, 1887289753242443812, 4611798168756031552, 387036685026304, 144837567291201536, 9224799203023212552, 10430341135050211593, 72921810179492612, 211108380057616, 5982064535803011072, 4574084336721920, 1153502048894060546, 76640360650244098, 1728434426478609, 4638718765927500945, 9225062286874386500, 5242192440454023200, 685743420878102528, 1482036808337328145, 2341889398502596616, 2267826620416, 16888791390224896, 432354465614401040, 36099441345692545, 360305700888936448, 288247971022127104, 621496997953699872, 1153502046880563204, 4582764665995266, 2256301216628737, 244338258870534184, 18014965483044865, 18155144860541184, 9223407841862223104, 14707205023994112, 154069335288064, 9438207846645888, 45150415830123008, 722833796149806080, 1441153882255270144, 1162212927621570577, 292745039061121, 9302143785895953, 1152939096936808993, 4501128875537, 5769111827054069762, 328764010856973700, 9260949496605757698]

class Rook {
    static let masks: [Bitboard] = generateRookMasks()
    static let lookUpTable: [[Bitboard]] = createRookLookupTable()
    
    static func generateRookMask(square: Int) -> Bitboard {
        
        let rank = square / 8
        let file = square % 8
        
        var rankMask = Bitboard.Masks.rank1 << (Bitboard(rank * 8))
        var fileMask = Bitboard.Masks.fileA << Bitboard(file)
        rankMask = rankMask & ~(Bitboard.Masks.fileA | Bitboard.Masks.fileH)
        fileMask = fileMask & ~(Bitboard.Masks.rank1 | Bitboard.Masks.rank8)
        return rankMask | fileMask
    }
    
    static func generateRookMasks() -> [Bitboard] {
        var rookMasks: [Bitboard] = Array(repeating: Bitboard(0), count: 64)
        for squareIndex in 0...63 {
            rookMasks[squareIndex] = generateRookMask(square: squareIndex)
        }
        return rookMasks
    }
    

    static func hashKeyRook(blockerBitboard: Bitboard, square: Int) -> Int {
        let mask = masks[square]
        let maskedBlockers = blockerBitboard & mask
        return magicIndex(magic: rookMagics[square], shift: rookShifts[square], blocker: maskedBlockers)
    }

    
    static func createLegalMoves(square: Int, blocker: Bitboard) -> Bitboard {
        var legalMoves = Bitboard(0)
        
        let rank = square / 8
        let file = square % 8
        
        // North
        for r in (0..<rank).reversed() {
            let targetSquare = r * 8 + file
            let bit = Bitboard.bit(at: targetSquare)
            legalMoves |= bit
            if blocker & bit != 0 {
                break
            }
        }
        
        // South
        for r in (rank+1..<8) {
            let targetSquare = r * 8 + file
            let bit = Bitboard.bit(at: targetSquare)
            legalMoves |= bit
            if blocker & bit != 0 {
                break
            }
        }
        
        // West
        for f in (0..<file).reversed() {
            let targetSquare = rank * 8 + f
            let bit = Bitboard.bit(at: targetSquare)
            legalMoves |= bit
            if blocker & bit != 0 {
                break
            }
        }
        
        // East
        for f in (file+1..<8) {
            let targetSquare = rank * 8 + f
            let bit = Bitboard.bit(at: targetSquare)
            legalMoves |= bit
            if blocker & bit != 0 {
                break
            }
        }
        return legalMoves
    }
    static func createRookLookupTable() -> [[Bitboard]] {
        var rookMovesLookup = (0..<64).map { square in
            Array(repeating: Bitboard(0), count: magicTableCount(shift: rookShifts[square]))
        }
        for square in 0...63 {
            let blockers = Magic.createAllBlockers(movementMask: masks[square])
            for blocker in blockers {
                let key = hashKeyRook(blockerBitboard: blocker, square: square)
                rookMovesLookup[square][key] = createLegalMoves(square: square, blocker: blocker)
            }
        }
        return rookMovesLookup
    }
}
