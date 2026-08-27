# Board representation

How to turn engine state into something you can draw on screen.

## `toBoardArrayRepresentation()`

```swift
let squares: [Int] = game.toBoardArrayRepresentation()
```

Returns a **64-element array**. Index = square (0 = a1, 63 = h8). Value = piece integer, or `0` for empty.

```
index:  0  1  2  3  4  5  6  7  …  63
square: a1 b1 c1 d1 e1 f1 g1 h1 … h8
```

## Piece integers

Pieces combine type + color (from `Piece.ColoredPieces`):

| Piece | Value |
|---|---|
| empty | `0` |
| white king | `9` |
| white pawn | `10` |
| white knight | `11` |
| white bishop | `12` |
| white rook | `13` |
| white queen | `14` |
| black king | `17` |
| black pawn | `18` |
| black knight | `19` |
| black bishop | `20` |
| black rook | `21` |
| black queen | `22` |

### Decode type and color

```swift
let piece = squares[28]  // e4

if piece == 0 {
    // empty
} else {
    let type = Piece.getType(piece: piece)   // .pawn, .rook, …
    let color = Piece.checkColor(piece: piece) // .white or .black
}
```

### Build a piece int

```swift
let whiteQueen = Piece.combine(type: .queen, color: .white)  // 14
```

## Example: map to your assets

```swift
func pieceImageName(at square: Int, game: Game) -> String? {
    let piece = game.toBoardArrayRepresentation()[square]
    guard piece != 0 else { return nil }

    let color = Piece.checkColor(piece: piece) == .white ? "w" : "b"
    let type: String
    switch Piece.getType(piece: piece) {
    case .king:   type = "K"
    case .queen:  type = "Q"
    case .rook:   type = "R"
    case .bishop: type = "B"
    case .knight: type = "N"
    case .pawn:   type = "P"
    default:     return nil
    }
    return "\(color)\(type)"  // e.g. "wK", "bP"
}
```

## Board orientation

The array is always from **white's view** (a1 = bottom-left for white). If your UI shows black at the bottom, flip when reading:

```swift
func displayIndex(engineSquare: Int, flipped: Bool) -> Int {
    if !flipped { return engineSquare }
    let file = engineSquare % 8
    let rank = engineSquare / 8
    return (7 - rank) * 8 + file
}
```

## Other useful `boardState` fields

| Field | Use |
|---|---|
| `currentTurnColor` | `.white` or `.black` — whose turn |
| `currentValidMoves` | legal moves for highlights / validation |
| `castlesAvailable` | set of `"K"`, `"Q"`, `"k"`, `"q"` |
| `enPassant` | `"-"` or square like `"e3"` |
| `lastMove` | previous `Move?` for last-move highlight |
| `halfmoveClock` | fifty-move rule counter |

## Game result

Don't infer checkmate from the board array alone — use `game.boardData`:

```swift
game.boardData.hasGameEnded   // Bool
game.boardData.gameResult       // .white, .black, .draw, .none
game.boardData.halfMoves        // halfmove clock for UI
```

## Bitboards (advanced)

Lower-level access lives on `game.boardState.bitboards` (`PieceBitboards`). Most UI apps only need `toBoardArrayRepresentation()`.

If you're doing engine dev or custom analysis, bitboards are `UInt64` masks per piece type. See `Bitboard` and `PieceBitboards` in the source.
