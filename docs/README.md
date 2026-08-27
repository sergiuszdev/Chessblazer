# Chessblazer docs

Integration guides for using Chessblazer inside your own app or tooling.

## Pick your path

| You want to… | Read this |
|---|---|
| Build a **Swift** chess app (SwiftUI, UIKit, macOS) | [integration/swift-library.md](integration/swift-library.md) |
| Talk to the engine from **any language** (Python, JS, Rust, etc.) | [integration/uci-subprocess.md](integration/uci-subprocess.md) |
| Understand move strings, squares, FEN | [reference/moves-and-notation.md](reference/moves-and-notation.md) |
| Render the board from engine data | [reference/board-representation.md](reference/board-representation.md) |
| Wire up UCI commands by hand | [reference/uci-protocol.md](reference/uci-protocol.md) |
| Configure Hash, book, syzygy, threads | [reference/uci-options.md](reference/uci-options.md) |

New here? Start with [getting-started.md](getting-started.md), then pick a path above.

## Library vs UCI — what's the difference?

**Swift library** (`import Chessblazer`)

- Runs in-process, no subprocess
- Good for native apps where you already have a `Game` instance
- Public API today: `Game`, legal moves, `findBestMove(depth:)`, `evaluate()`
- Fixed-depth search only (no movetime / book / syzygy through this API yet)

**UCI subprocess** (`ChessblazerUCI` binary)

- Spawn the binary, write commands to stdin, read stdout
- Good for non-Swift apps, bots, engine tournaments
- Full engine: opening book, syzygy, threads, clock-aware search, `info` lines

If you need book, syzygy, or `go movetime` — use UCI (for now).

## Examples

- [examples/minimal-swift-app.swift](examples/minimal-swift-app.swift) — human vs engine loop in ~60 lines
- [examples/uci-session.txt](examples/uci-session.txt) — copy-paste terminal session
