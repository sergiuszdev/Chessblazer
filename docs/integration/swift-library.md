# Swift library integration

Use this when you're building a native Swift app and want the engine in-process.

## Minimal example

```swift
import Chessblazer

let game = Game()

// engine plays as the side to move
let sideToMove = game.boardState.currentTurnColor
let engineIsWhite = sideToMove == .white

if let move = findBestMove(
    game: game,
    depth: 6,
    maximizingPlayer: engineIsWhite
) {
    game.makeMove(move: move)
}
```

`findBestMove` searches from the current position and returns a `Move?`. Call `game.makeMove(move:)` to apply it.

Full runnable version: [examples/minimal-swift-app.swift](../examples/minimal-swift-app.swift).

## Core types

### `Game`

Your main handle. Owns board state and game-over logic.

| Method / property | What it does |
|---|---|
| `startNewGame()` | Standard starting position |
| `loadFromFen(fen:)` | Load any legal FEN |
| `makeMove(move:)` | Play a move, refresh legal moves and game result |
| `undoMove()` | Take back one move |
| `findMove(notation:)` | Parse UCI string (`"e2e4"`) → legal `Move?` |
| `boardState` | Position, side to move, legal moves |
| `boardData` | `hasGameEnded`, `gameResult`, halfmove clock |
| `toBoardArrayRepresentation()` | 64-element array for rendering — see [board-representation.md](../reference/board-representation.md) |

### `findBestMove`

```swift
public func findBestMove(
    game: Game,
    depth: Int,
    maximizingPlayer: Bool
) -> Move?
```

- `depth` — search depth (higher = stronger, slower)
- `maximizingPlayer` — `true` if the side to move is the one trying to *maximize* the score (white when it's white's turn)

`findBestMove` blocks until the search finishes. Run it off the main thread in UI apps:

```swift
Task.detached {
    let move = findBestMove(game: game, depth: 8, maximizingPlayer: true)
    // hop back to MainActor to update UI
}
```

### `evaluate`

```swift
public func evaluate(bitboards: PieceBitboards) -> Int
```

Static evaluation in centipawns from **white's perspective**. Positive = good for white.

Handy for analysis UI, not needed for playing.

## Typical app flow

### 1. Start or load a position

```swift
let game = Game()
game.startNewGame()

// or
game.loadFromFen(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
```

### 2. Show legal moves (highlights, click validation)

```swift
let legal = game.boardState.currentValidMoves
let sideToMove = game.boardState.currentTurnColor
```

Each `Move` has `fromSquare` and `targetSquare` (0 = a1 … 63 = h8). See [moves-and-notation.md](../reference/moves-and-notation.md).

### 3. User picks a move

If your UI works in UCI strings:

```swift
if let move = game.findMove(notation: "e2e4") {
    game.makeMove(move: move)
}
```

`findMove` only returns moves that are **legal right now**. Illegal input → `nil`.

### 4. Engine replies

```swift
let whiteToMove = game.boardState.currentTurnColor == .white

guard let reply = findBestMove(
    game: game,
    depth: 6,
    maximizingPlayer: whiteToMove
) else { return }

game.makeMove(move: reply)
```

### 5. Check for game over

```swift
if game.boardData.hasGameEnded {
    switch game.boardData.gameResult {
    case .white:  // white won
    case .black:  // black won
    case .draw:   // draw
    case .none:   // shouldn't happen when hasGameEnded is true
    }
}
```

## Rendering the board

```swift
let squares = game.toBoardArrayRepresentation()
// squares[0] = a1 piece, squares[63] = h8 piece
// 0 = empty, see board-representation.md for piece ints
```

## Move strings in the library API

UCI move strings (`e2e4`, `e1g1`, `a7a8q`) are how the engine talks externally. In the library:

- **Input:** `game.findMove(notation: "e2e4")`
- **Output:** `Move` has `fromSquare` / `targetSquare` — convert to UCI yourself, or match against `currentValidMoves`

`moveToNotation` exists inside the package but isn't public yet. The example file includes a small helper you can copy.

## What the library API does *not* expose (yet)

Use UCI instead if you need these:

| Feature | Library API | UCI |
|---|---|---|
| `go movetime` / clock | ❌ | ✅ |
| Opening book | ❌ | ✅ (`Book File`) |
| Syzygy tablebases | ❌ | ✅ (`SyzygyPath`) |
| Multi-threaded search | ❌ | ✅ (`Threads`) |
| Search `info` lines | ❌ | ✅ |
| Configurable hash size | ❌ | ✅ (`Hash`) |

See [uci-subprocess.md](uci-subprocess.md).

## Thread safety

- `Game` is not designed for concurrent mutation — one owner thread (or use a lock).
- `findBestMove` runs a CPU-heavy search — don't call it on the main thread.
- The `Engine` class (UCI wrapper) has its own locking for subprocess-style use, but most Swift apps use `Game` + `findBestMove` directly.

## Suggested search depths

Rough guide on modern hardware — tune for your target devices:

| Depth | Feel |
|---|---|
| 4–5 | casual / fast reply |
| 6–8 | decent club level |
| 10+ | slow, much stronger |

Depth is ply (half-moves), not "plies to mate".
