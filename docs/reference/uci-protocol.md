# UCI protocol reference

Command-by-command reference for talking to `ChessblazerUCI`. Based on the [UCI spec](https://www.chessprogramming.org/UCI).

## Engine → GUI (startup)

After launch, the engine waits for input. It does not send anything until you send `uci`.

## Handshake

```text
→ uci
← id name Chessblazer alpha 0.002
← id author sergiusz
← option name Hash type spin default 16 min 1 max 4096
← option name Threads type spin default 1 min 1 max 256
← … (all options — see uci-options.md)
← uciok
```

## Options

```text
→ setoption name Hash value 64
→ setoption name Book File value /path/to/book.bin
→ setoption name SyzygyPath value /path/to/syzygy
→ isready
← readyok
```

**Always** `isready` after `setoption`. Book and syzygy load during this phase.

Option names are case-insensitive (`Book File` = `book file`).

## New game

```text
→ ucinewgame
```

Clears transposition table and internal state. Send before the first `position` of a new game.

## Position

```text
→ position startpos
→ position startpos moves e2e4 e7e5
→ position fen <fen-string>
→ position fen <fen-string> moves e2e4 e7e5
```

The engine applies moves in order. Illegal moves in the list are skipped with:

```text
← info string unknown move <notation>
```

## Search

```text
→ go depth 10
→ go movetime 500
→ go wtime 300000 btime 300000 winc 3000 binc 3000
→ go infinite
```

### Responses during search

```text
← info depth 1 score cp 15
← info depth 2 score cp 18
← …
← info depth 10 score cp 22
← bestmove g1f3
```

Only the **main thread** emits `info` and `bestmove`. Helper threads (when `Threads` > 1) search silently.

### `info` format (current)

Chessblazer keeps it minimal:

```text
info depth <n> score cp <centipawns>
```

`score cp` is from the side to move's view. No `pv`, `nodes`, or `nps` yet.

### End of search

```text
← bestmove e2e4
```

Special cases:

- `bestmove 0000` — no legal move
- Book / syzygy hit at root → `bestmove` immediately, often no `info` lines

## Stop

```text
→ stop
← bestmove <move>
```

Use when the user moves during ponder/search, or to abort `go infinite`.

## Ponder

`Ponder` UCI option exists (default `false`). `ponder` and `ponderhit` tokens are parsed; full ponder support is minimal — don't rely on it for production yet.

## Quit

```text
→ quit
```

Process exits. Close stdin or send `quit` before killing the process if you want a clean shutdown.

## Typical game loop

```text
uci
… uciok …

setoption name Hash value 128
setoption name Threads value 2
isready
readyok

ucinewgame
position startpos
go wtime 600000 btime 600000 winc 0 binc 0
… info …
bestmove e2e4

position startpos moves e2e4
go wtime 598000 btime 600000 winc 0 binc 0
…
bestmove e7e5

position startpos moves e2e4 e7e5
go movetime 2000
…
bestmove g1f3

quit
```

## Commands the engine ignores

Unknown first tokens are silently ignored (no error line).

## `Engine` class (Swift, in-process UCI)

If you embed the engine in Swift without a subprocess:

```swift
import Chessblazer

let engine = Engine()
engine.processInput(command: "uci")
engine.processInput(command: "isready")
engine.processInput(command: "position startpos")
engine.processInput(command: "go depth 6")
```

Output goes to **stdout** via `print`. For a real app you'd want to redirect that — subprocess is usually easier than fighting stdout.

## Not supported yet

- `debug`
- `register`
- `setoption` confirmation lines
- `UCI_ShowWDL` output (option exists, no WDL in `info` yet)
- `UCI_Chess960` (option exists, standard chess only)
- `go nodes` / `go mate` limits (parsed but not enforced)
