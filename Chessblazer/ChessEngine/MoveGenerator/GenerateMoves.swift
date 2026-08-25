//
//  GenerateMoves.swift
//  Chessblazer
//
//  Created by sergiusz on 30/07/2024.
//

import Foundation

func generateAllPossibleMoves(bitboards: [Int: Bitboard], currentColor: Piece.Color, moves: inout [Move], lastMove: Move?, castlesAvailable: Set<Character>) {
    
    moves.removeAll()
    
    
    if let lastMove = lastMove {
        moves.append(contentsOf: enPassantCheck(bitboards: bitboards, lastMove: lastMove))
    }
    
    
    for bitboard in bitboards {
        if Piece.checkColor(piece: bitboard.key) == currentColor {
            var pieceSquares = [Int]()
            var copyBitboard: Bitboard = bitboard.value
            
            while copyBitboard != 0 {
                pieceSquares.append(Bitboard.popLSB(&copyBitboard))
            }
            let pieceType = Piece.getType(piece: bitboard.key)
            

            
            for square in pieceSquares {
                switch pieceType {
                case .queen:
                    generateQueenMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                case .bishop:
                    generateBishopMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                case .rook:
                    generateRookMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                case .pawn:
                    generatePawnMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                case .king:
                    generateKingMovesBitboard(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                    generateCastles(bitboards: bitboards, currentColor: currentColor, moves: &moves, castlesAvailable: castlesAvailable)

                case .knight:
                    generateKnightMoves(bitboards: bitboards, currentColor: currentColor, square: square, moves: &moves)
                    
                default:
                    print("\(pieceType) is not found while generating moves")
                    
                }
            }
        }
    }
}

func generateAllAttackedSquares(bitboards: [Int: Bitboard], currentColor: Piece.Color) -> Bitboard {
    let enemyColor = currentColor.getOppositeColor()
    var attackBitboard = Bitboard(0)
    let friendlyBitboard = currentColor == .black ? Magic.whitePiecesBitboards(bitboards: bitboards) : Magic.blackPiecesBitboards(bitboards: bitboards)
    for bitboard in bitboards {
        if Piece.checkColor(piece: bitboard.key) == enemyColor {
            var pieceSquares = [Int]()
            var copyBitboard: Bitboard = bitboard.value
            
            while copyBitboard != 0 {
                pieceSquares.append(Bitboard.popLSB(&copyBitboard))
            }
            let pieceType = Piece.getType(piece: bitboard.key)
            
            for square in pieceSquares {
                switch pieceType {
                case .queen:
                    attackBitboard = attackBitboard | generateQueenAttacks(bitboards: bitboards, square: square, friendlyBitboard: friendlyBitboard)
                    
                case .bishop:
                    attackBitboard = attackBitboard | generateBishopAttacks(bitboards: bitboards, square: square, friendlyBitboard: friendlyBitboard)
                    
                case .rook:
                    attackBitboard = attackBitboard | generateRookAttacks(bitboards: bitboards, square: square, friendlyBitboard: friendlyBitboard)
                case .pawn:
                    attackBitboard = attackBitboard | generatePawnAttacks(currentColor: currentColor.getOppositeColor(), square: square)
                    
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
    let lastMove: Move? = boardState.performedMovesList.last?.move
    generateAllPossibleMoves(bitboards: boardState.bitboards, currentColor: boardState.currentTurnColor, moves: &possibleMoves, lastMove: lastMove, castlesAvailable: boardState.castlesAvailable)

    
    for move in possibleMoves {
        let newState = GameEngine.makeMoveOnly(boardState: boardState, move: move)
        if !checkIfCheck(boardState: newState) {
            legalMoves.append(move)
        }
    }
    
    return legalMoves
}
