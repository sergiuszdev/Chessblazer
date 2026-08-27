# Moves and notation

Chessblazer uses **UCI move format** everywhere — engine output, `position moves`, `game.findMove(notation:)`, opening books.

## UCI move strings

Format: `from` + `to` + optional `promotion`

| Move | UCI string |
|---|---|
| e2 → e4 | `e2e4` |
| White castles kingside | `e1g1` |
| White castles queenside | `e1c1` |
| Black castles kingside | `e8g8` |
| Pawn promotes to queen | `a7a8q` |
| Pawn promotes to knight | `a7a8n` |

Promotion letters: `q` queen, `r` rook, `b` bishop, `n` knight.

### Castling

UCI encodes castling as **king to destination square**, not rook move.

- ✅ `e1g1` (white kingside)
- ❌ `e1h1` (polyglot book internal format — not valid UCI here)

`game.findMove(notation: "e1h1")` returns `nil`. Use `e1g1`.

### Invalid / no move

- `bestmove 0000` — engine has no legal move (checkmate / stalemate with no moves)
- `game.findMove(notation:)` returns `nil` for illegal or malformed input

## Square index

Squares are integers **0–63**, row-major from white's perspective:

```
  a b c d e f g h
8 56 57 58 59 60 61 62 63
7 48 49 50 51 52 53 54 55
6 40 41 42 43 44 45 46 47
5 32 33 34 35 36 37 38 39
4 24 25 26 27 28 29 30 31
3 16 17 18 19 20 21 22 23
2  8  9 10 11 12 13 14 15
1  0  1  2  3  4  5  6  7
```

`Move.fromSquare` and `Move.targetSquare` use this indexing.

Convert index → file/rank:

```swift
let file = square % 8          // 0 = a … 7 = h
let rank = square / 8 + 1      // 1 … 8
```

Convert `"e4"` → index: file `e` = 4, rank 4 → `(4-1)*8 + 4` = **28**.

## FEN

Load positions with:

```swift
game.loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
```

Standard [FEN](https://www.chessprogramming.org/Forsyth-Edwards_Notation) — rank 8 first, `/` between ranks, side to move, castling rights, en passant square, halfmove clock, fullmove number.

UCI position with FEN:

```text
position fen rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1
```

## Matching user input to a `Move`

### By UCI string (easiest)

```swift
if let move = game.findMove(notation: "e2e4") {
    game.makeMove(move: move)
}
```

`findMove` checks the parsed move against `boardState.currentValidMoves`, including promotion piece when the notation includes `q/r/b/n`.

### By from / to squares

```swift
let tappedFrom = 12  // e2
let tappedTo = 28    // e4

if let move = game.boardState.currentValidMoves.first(where: {
    $0.fromSquare == tappedFrom && $0.targetSquare == tappedTo
}) {
    game.makeMove(move: move)
}
```

If multiple legal moves share the same from/to (rare — mainly underpromotion), filter by `promotionPiece` too.

## Promotion in the UI

When a pawn reaches the last rank, `currentValidMoves` may contain several moves with the same from/to but different `promotionPiece`. Show a picker, then:

```swift
// user picked queen promotion
if let move = game.findMove(notation: "a7a8q") {
    game.makeMove(move: move)
}
```

## Converting `Move` → UCI string

Not public API yet. Copy this helper into your app:

```swift
func uciNotation(for move: Move) -> String {
    guard let from = move.fromSquare, let to = move.targetSquare else { return "0000" }
    let files = "abcdefgh"
    func square(_ s: Int) -> String {
        let f = files[files.index(files.startIndex, offsetBy: s % 8)]
        return "\(f)\(s / 8 + 1)"
    }
    var notation = "\(square(from))\(square(to))"
    if move.promotionPiece != 0 {
        let letter: String
        switch Piece.getType(piece: move.promotionPiece) {
        case .queen:  letter = "q"
        case .rook:   letter = "r"
        case .bishop: letter = "b"
        case .knight: letter = "n"
        default:      letter = ""
        }
        notation += letter
    }
    return notation
}
```

## Score in UCI `info` lines

During search the engine prints:

```text
info depth 8 score cp 25
```

`score cp` is from the **side to move's** perspective. Positive = good for the player whose turn it is.

Mate scores use `score mate N` (not implemented in current info output — only `cp` today).
