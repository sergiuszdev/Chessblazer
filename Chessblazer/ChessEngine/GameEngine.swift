//
//  GameEngine.swift
//  Chessblazer
//
//  Created by sergiusz on 11/10/2024.
//

import Foundation

class GameEngine {
    
    static func makeMove(boardState: BoardState, move: Move) -> BoardState {
        
        var boardStateCopy = boardState
        
        let from = move.fromSquare!
        let target = move.targetSquare!
        
        let pieceValue = move.pieceValue
        
        if move.castling {
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: move.castlingKingDestination)
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: move.captureValue, from: target, target: move.castlingRookDestination)
            
            if pieceValue == Piece.ColoredPieces.whiteKing.rawValue {
                boardStateCopy.castlesAvailable.remove("K")
                boardStateCopy.castlesAvailable.remove("Q")
            } else if pieceValue == Piece.ColoredPieces.blackKing.rawValue {
                boardStateCopy.castlesAvailable.remove("k")
                boardStateCopy.castlesAvailable.remove("q")
            }
            
        } else if move.promotionPiece != 0 {
            let newPiece = move.promotionPiece
            let captureValue = move.captureValue

            var pawnBitboard = boardStateCopy.bitboards[pieceValue]!
            pawnBitboard = pawnBitboard & ~(Bitboard(1) << Bitboard(from))
            var newPieceBitboard = boardStateCopy.bitboards[newPiece]!
            newPieceBitboard = newPieceBitboard | (Bitboard(1) << Bitboard(target))
            boardStateCopy.bitboards[newPiece] = newPieceBitboard
            boardStateCopy.bitboards[pieceValue] = pawnBitboard

            if captureValue != 0 {
                var captureBitboard = boardStateCopy.bitboards[captureValue]!
                captureBitboard = captureBitboard & ~(Bitboard(1) << Bitboard(target))
                boardStateCopy.bitboards[captureValue] = captureBitboard
            }

            
            
        } else if move.enPasssantCapture != 0 {
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: target)
            let enPassantCapture = move.enPasssantCapture
            let captured = move.captureValue
            boardStateCopy.bitboards[captured] = boardStateCopy.bitboards[captured]! & ~Bitboard(1 << enPassantCapture)
        } else {
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: target)
            
            switch pieceValue {
            case Piece.ColoredPieces.whiteKing.rawValue:
                boardStateCopy.castlesAvailable.remove("K")
                boardStateCopy.castlesAvailable.remove("Q")
                
            case Piece.ColoredPieces.blackKing.rawValue:
                boardStateCopy.castlesAvailable.remove("k")
                boardStateCopy.castlesAvailable.remove("q")
                
            case Piece.ColoredPieces.whiteRook.rawValue:
                if from == 0 {
                    boardStateCopy.castlesAvailable.remove("Q")
                } else if from == 7 {
                    boardStateCopy.castlesAvailable.remove("K")
                }
            case Piece.ColoredPieces.blackRook.rawValue:
                if from == 56 {
                    boardStateCopy.castlesAvailable.remove("q")
                } else if from == 63 {
                    boardStateCopy.castlesAvailable.remove("k")
                }
            default:
                break
            }
        }
        return boardStateCopy
    }
    
    
    
    static func makeMoveOnly(boardState: BoardState, move: Move) -> BoardState {
        
        var boardStateCopy = boardState
        
        let from = move.fromSquare!
        let target = move.targetSquare!
        
        let pieceValue = move.pieceValue
        
        if move.castling {
            
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: move.castlingKingDestination)
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: move.captureValue, from: target, target: move.castlingRookDestination)
            
            if pieceValue == Piece.ColoredPieces.whiteKing.rawValue {
                boardStateCopy.castlesAvailable.remove("K")
                boardStateCopy.castlesAvailable.remove("Q")
            } else if pieceValue == Piece.ColoredPieces.blackKing.rawValue {
                boardStateCopy.castlesAvailable.remove("k")
                boardStateCopy.castlesAvailable.remove("q")
            }
        }  else if move.promotionPiece != 0 {
            let newPiece = move.promotionPiece
            let captureValue = move.captureValue

            var pawnBitboard = boardStateCopy.bitboards[pieceValue]!
            pawnBitboard = pawnBitboard & ~(Bitboard(1) << Bitboard(from))
            var newPieceBitboard = boardStateCopy.bitboards[newPiece]!
            newPieceBitboard = newPieceBitboard | (Bitboard(1) << Bitboard(target))
            boardStateCopy.bitboards[newPiece] = newPieceBitboard
            boardStateCopy.bitboards[pieceValue] = pawnBitboard

            if captureValue != 0 {
                var captureBitboard = boardStateCopy.bitboards[captureValue]!
                captureBitboard = captureBitboard & ~(Bitboard(1) << Bitboard(target))
                boardStateCopy.bitboards[captureValue] = captureBitboard
            }

            
        } else if move.enPasssantCapture != 0 {
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: target)
            let enPassantCapture = move.enPasssantCapture
            let captured = move.captureValue
            boardStateCopy.bitboards[captured] = boardStateCopy.bitboards[captured]! & ~Bitboard(1 << enPassantCapture)
        } else {
            
            boardStateCopy.bitboards = GameEngine.makeMoveOperations(bitboards: boardStateCopy.bitboards, pieceValue: pieceValue, from: from, target: target)
            
            switch pieceValue {
            case Piece.ColoredPieces.whiteKing.rawValue:
                boardStateCopy.castlesAvailable.remove("K")
                boardStateCopy.castlesAvailable.remove("Q")
                
            case Piece.ColoredPieces.blackKing.rawValue:
                boardStateCopy.castlesAvailable.remove("k")
                boardStateCopy.castlesAvailable.remove("q")
                
            case Piece.ColoredPieces.whiteRook.rawValue:
                if from == 0 {
                    boardStateCopy.castlesAvailable.remove("Q")
                } else if from == 7 {
                    boardStateCopy.castlesAvailable.remove("K")
                }
            case Piece.ColoredPieces.blackRook.rawValue:
                if from == 56 {
                    boardStateCopy.castlesAvailable.remove("q")
                } else if from == 63 {
                    boardStateCopy.castlesAvailable.remove("k")
                }
            default:
                break
            }
        }
        boardStateCopy.attackBitboard = generateAllAttackedSquares(bitboards: boardStateCopy.bitboards, currentColor: boardStateCopy.currentTurnColor)
        return boardStateCopy
    }

    
    static func makeMoveOperations(bitboards: [Int: Bitboard], pieceValue: Int, from: Int, target: Int) -> [Int: Bitboard] {
        var bitboardsCopy = bitboards
        var bitboard = bitboardsCopy[pieceValue]! //it's expected to cause exception if something is wrong in code before
        bitboard = bitboard & ~(Bitboard(1) << Bitboard(from))
        bitboard = bitboard | (Bitboard(1) << Bitboard(target))
        bitboardsCopy[pieceValue] = bitboard
        for (key, value) in bitboardsCopy {
            if (key != pieceValue) && (value & (Bitboard(1) << Bitboard(target))) != 0 {
                bitboardsCopy[key] = bitboardsCopy[key]! & ~(Bitboard(1) << Bitboard(target))
                break
            }
        }
        return bitboardsCopy
    }
    
    static func loadBoardFromFen(fen: String) -> BoardState {
        var boardState = BoardState(currentTurnColor: .white)
        let args = fen.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if args.count > 1 {
            boardState.currentTurnColor = args[1] == "w" ? .white : .black
        }
        boardState.castlesAvailable.removeAll()
        if args.count > 2 {
            for letter in args[2] {
                if letter == "-" { break } else { boardState.castlesAvailable.insert(letter) }
            }
        }
        if args.count > 3 {
            boardState.enPassant = args[3]
        }
        let ranks: [String] = (args.first ?? "").components(separatedBy: "/")
        var index = 0
        for rank in ranks.reversed() {
            
            for char in rank {
                if char.isNumber {
                    for _ in 0..<char.wholeNumberValue! {
                        index+=1
                    }
                } else {
                    let piece: Int = Piece.combine(type: Piece.PiecesDict[char.lowercased().first!] ?? Piece.PieceType.empty, color: char.isUppercase ? Piece.Color.white : Piece.Color.black)
                    
                    boardState.bitboards[piece] = (boardState.bitboards[piece] ?? Bitboard(0)) | (Bitboard(1) << Bitboard(UInt64(index)))
                    index+=1
                }
            }
        }
        
        return boardState
    }
}
