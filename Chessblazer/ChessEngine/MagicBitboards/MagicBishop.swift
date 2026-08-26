//
//  MagicBishop.swift
//  Chessblazer
//
//  Created by sergiusz on 06/09/2024.
//

import Foundation

let bishopMagics: [UInt64] = [9530267746158843920, 36206101892700160, 310749199225323561, 1154051806998317324, 288513161097656322, 1225265250907987968, 576500352439156768, 18139745251492096, 9223373282533720336, 290822201970817, 9223706496027598848, 551987185680, 581642187964480, 276102807553, 4611759896294146048, 9223394577120100642, 9225764600229790208, 281544115751940, 70508339003780, 176007894090752, 35185446912002, 8937896158208, 613052508020945152, 9224726637394817088, 1691083262136640, 141031727449092, 1152925902691108992, 4423817363616, 70394581131264, 1729523132040552448, 342344219664320512, 11531537286609065984, 4508014855848064, 281758715085088, 1154047414714253472, 1297037105670655232, 633593860727040, 1153098526054416896, 88579674538240, 288828656506159168, 1126741921775616, 21999359369472, 4611704194863235328, 4616189626653345832, 4653201995337856, 35807154935296, 4507997808623696, 1266777015714120, 577589409714110976, 216736831755124816, 1585834434081407488, 1441156279174184960, 36031008122077184, 11529223846798297128, 18174946601601024, 9631998901551808, 4611759825364847105, 82195232997245186, 4400294674714, 109951163434512, 151015723588699136, 565175183737088, 5188463432512439296, 3993499317833920]
let bishopShifts: [Int] = [57, 57, 57, 57, 57, 57, 57, 57, 57, 55, 55, 55, 55, 55, 55, 57, 57, 55, 53, 53, 53, 53, 55, 57, 57, 55, 53, 51, 51, 53, 55, 57, 57, 55, 53, 51, 51, 53, 55, 57, 57, 55, 53, 53, 53, 53, 55, 57, 57, 55, 55, 55, 55, 55, 55, 57, 57, 57, 57, 57, 57, 57, 57, 57]

class Bishop {
    static let masks: [Bitboard] = generateBishopMasks()
    
    static let lookUpTable: [[Bitboard]] = createBishopLookupTable()

    static func generateBishopMask(square: Int) -> Bitboard {
        let rank = square / 8
        let file = square % 8
        var mask = Bitboard(0)
        for offset in 1..<8 {
            // NE
            if rank + offset < 8 && file + offset < 8 {
                mask = mask | Bitboard(1) << Bitboard(((rank + offset) * 8 + (file + offset)))
            }
            // NW
            if rank + offset < 8 && file - offset >= 0 {
                mask = mask | Bitboard(1) << Bitboard((rank + offset) * 8 + (file - offset))
            }
            // SE
            if rank - offset >= 0 && file + offset < 8 {
                mask = mask | Bitboard(1) << Bitboard((rank - offset) * 8 + (file + offset))
            }
            // SW
            if rank - offset >= 0 && file - offset >= 0 {
                mask = mask | Bitboard(1) << Bitboard((rank - offset) * 8 + (file - offset))
            }
        }
        
        return mask
    }
    
    static func generateBishopMasks() -> [Bitboard] {
        var bishopMasks: [Bitboard] = Array(repeating: Bitboard(0), count: 64)
        for squareIndex in 0...63 {
            bishopMasks[squareIndex] = generateBishopMask(square: squareIndex)
        }
        return bishopMasks
    }
    
    static func hashKeyBishop(blockerBitboard: Bitboard, square: Int) -> Int {
        magicIndex(magic: bishopMagics[square], shift: bishopShifts[square], blocker: blockerBitboard)
    }
    
    static func createBishopLookupTable() -> [[Bitboard]] {
        var bishopMovesLookup = (0..<64).map { square in
            Array(repeating: Bitboard(0), count: magicTableCount(shift: bishopShifts[square]))
        }
        for square in 0...63 {
            let blockers = Magic.createAllBlockers(movementMask: masks[square])
            for blocker in blockers {
                let key = hashKeyBishop(blockerBitboard: blocker, square: square)
                bishopMovesLookup[square][key] = createLegalMoves(square: square, blocker: blocker)
            }
        }
        return bishopMovesLookup
    }
    

    static func createLegalMoves(square: Int, blocker: Bitboard) -> Bitboard {
        var legalMoves = Bitboard(0)
        
        // NE, NW, SE, SW directions
        let directions: [(Int, Int)] = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (deltaRow, deltaCol) in directions {
            var currentRow = square / 8
            var currentCol = square % 8
            
            while true {
                currentRow += deltaRow
                currentCol += deltaCol
                
                if currentRow < 0 || currentRow >= 8 || currentCol < 0 || currentCol >= 8 {
                    break
                }
                
                let newSquare = currentRow * 8 + currentCol
                legalMoves = Bitboard(legalMoves | 1 << newSquare)
                
                if (blocker & (1 << newSquare)) != 0 {
                    break
                }
            }
        }
        
        return legalMoves
    }
}
