//
//  GenerateMoves.swift
//  Chessblazer
//
//  Created by sergiusz on 30/07/2024.
//

import Foundation

func generateAllPossibleMoves(bitboards: PieceBitboards, currentColor: Piece.Color, moves: inout [Move], lastMove: Move?, castlesAvailable: Set<Character>) {
    
    moves.removeAll()
    let occupancy = Occupancy.from(bitboards: bitboards)
    let attackedSquares = generateAllAttackedSquares(bitboards: bitboards, currentColor: currentColor, occupancy: occupancy)
    
    if let lastMove = lastMove {
        let enPassantMoves = enPassantCheck(bitboards: bitboards, lastMove: lastMove)
            .filter { Piece.checkColor(piece: $0.pieceValue) == currentColor }
        moves.append(contentsOf: enPassantMoves)
    }
    
    var generatedKingMoves = false
    bitboards.forEachOccupied { piece, board in
        if Piece.checkColor(piece: piece) == currentColor {
            var pieceSquares = [Int]()
            var copyBitboard: Bitboard = board
            
            while copyBitboard != 0 {
                pieceSquares.append(Bitboard.popLSB(&copyBitboard))
            }
            let pieceType = Piece.getType(piece: piece)
            
            for square in pieceSquares {
                switch pieceType {
                case .queen:
                    generateQueenMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves, occupancy: occupancy)
                case .bishop:
                    generateBishopMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves, occupancy: occupancy)
                case .rook:
                    generateRookMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves, occupancy: occupancy)
                case .pawn:
                    generatePawnMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves, occupancy: occupancy)
                case .king:
                    if !generatedKingMoves {
                        generateKingMovesBitboard(bitboards: bitboards, currentColor: currentColor, moves: &moves, occupancy: occupancy, attackedSquares: attackedSquares)
                        generateCastles(bitboards: bitboards, currentColor: currentColor, moves: &moves, castlesAvailable: castlesAvailable, occupancy: occupancy, attackedSquares: attackedSquares)
                        generatedKingMoves = true
                    }
                case .knight:
                    generateKnightMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves, occupancy: occupancy)
                    
                default:
                    print("\(pieceType) is not found while generating moves")
                    
                }
            }
        }
    }
}

func generateAllAttackedSquares(bitboards: PieceBitboards, currentColor: Piece.Color, occupancy: Occupancy? = nil) -> Bitboard {
    let occ = occupancy ?? Occupancy.from(bitboards: bitboards)
    let enemyColor = currentColor.getOppositeColor()
    var attackBitboard = Bitboard(0)
    let friendlyBitboard = occ.friendly(for: enemyColor)
    bitboards.forEachOccupied { piece, board in
        if Piece.checkColor(piece: piece) == enemyColor {
            var pieceSquares = [Int]()
            var copyBitboard: Bitboard = board
            
            while copyBitboard != 0 {
                pieceSquares.append(Bitboard.popLSB(&copyBitboard))
            }
            let pieceType = Piece.getType(piece: piece)
            
            for square in pieceSquares {
                switch pieceType {
                case .queen:
                    attackBitboard = attackBitboard | generateQueenAttacks(square: square, friendlyBitboard: friendlyBitboard, occupancy: occ)
                    
                case .bishop:
                    attackBitboard = attackBitboard | generateBishopAttacks(square: square, friendlyBitboard: friendlyBitboard, occupancy: occ)
                    
                case .rook:
                    attackBitboard = attackBitboard | generateRookAttacks(square: square, friendlyBitboard: friendlyBitboard, occupancy: occ)
                case .pawn:
                    attackBitboard = attackBitboard | generatePawnAttacks(currentColor: enemyColor, square: square)
                    
                case .king:
                    attackBitboard = attackBitboard | generateKingAttacks(square: square, friendlyBitboard: friendlyBitboard)
                    
                case .knight:
                    attackBitboard = attackBitboard | generateKnightAttacks(square: square, friendlyBitboard: friendlyBitboard)
                    
                default:
                    print("\(pieceType) is not found while generating attackBitboard")
                    
                }
            }
        }
    }
    return attackBitboard
}

func generateAllLegalMoves(boardState: BoardState) -> [Move] {
    
    var possibleMoves = [Move]()
    var legalMoves = [Move]()
    let lastMove: Move? = boardState.lastMove
    generateAllPossibleMoves(bitboards: boardState.bitboards, currentColor: boardState.currentTurnColor, moves: &possibleMoves, lastMove: lastMove, castlesAvailable: boardState.castlesAvailable)

    
    for move in possibleMoves {
        let newState = GameEngine.makeMoveOnly(boardState: boardState, move: move)
        if !checkIfCheck(boardState: newState) {
            legalMoves.append(move)
        }
    }
    
    return legalMoves
}
