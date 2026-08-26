//
//  GenerateMoves.swift
//  Chessblazer
//
//  Created by sergiusz on 30/07/2024.
//

import Foundation

func generateAllPossibleMoves(bitboards: PieceBitboards, currentColor: Piece.Color, moves: inout [Move], lastMove: Move?, castlesAvailable: Set<Character>, includeKingAndCastles: Bool = true) {
    
    moves.removeAll()
    let occupancy = Occupancy.from(bitboards: bitboards)
    let attackedSquares = includeKingAndCastles
        ? generateAllAttackedSquares(bitboards: bitboards, currentColor: currentColor, occupancy: occupancy)
        : 0
    
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
                    if includeKingAndCastles && !generatedKingMoves {
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
    guard let info = PinCheckInfo.compute(boardState: boardState) else { return [] }
    
    var legalMoves = [Move]()
    let occupancy = boardState.occupancy
    generateKingMovesBitboard(
        bitboards: boardState.bitboards,
        currentColor: boardState.currentTurnColor,
        moves: &legalMoves,
        occupancy: occupancy,
        attackedSquares: info.unsafe
    )
    if info.doubleCheck {
        return legalMoves
    }
    if !info.inCheck {
        generateCastles(
            bitboards: boardState.bitboards,
            currentColor: boardState.currentTurnColor,
            moves: &legalMoves,
            castlesAvailable: boardState.castlesAvailable,
            occupancy: occupancy,
            attackedSquares: info.unsafe
        )
    }
    
    var possibleMoves = [Move]()
    generateAllPossibleMoves(
        bitboards: boardState.bitboards,
        currentColor: boardState.currentTurnColor,
        moves: &possibleMoves,
        lastMove: boardState.lastMove,
        castlesAvailable: boardState.castlesAvailable,
        includeKingAndCastles: false
    )
    
    for move in possibleMoves {
        guard let from = move.fromSquare, let to = move.targetSquare else { continue }
        guard info.allowsNonKingMove(from: from, to: to, capturedEP: move.enPasssantCapture) else { continue }
        if move.enPasssantCapture != 0
            && !isEnPassantLegal(bitboards: boardState.bitboards, color: boardState.currentTurnColor, move: move) {
            continue
        }
        legalMoves.append(move)
    }
    
    return legalMoves
}
