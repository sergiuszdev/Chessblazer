# UCI options

All options advertised after `uci`. Set with:

```text
setoption name <Name> value <Value>
```

Then `isready` → wait for `readyok`.

## Hash

| | |
|---|---|
| Type | spin (MB) |
| Default | `16` |
| Range | 1 – 4096 |

Transposition table size. Bigger = more positions remembered, usually stronger and more RAM.

```text
setoption name Hash value 128
```

Applied when the next search starts (`go`).

## Threads

| | |
|---|---|
| Type | spin |
| Default | `1` |
| Range | 1 – 256 |

Lazy SMP — helper threads search the same position in parallel and share the TT. Main thread picks the move and prints `info` / `bestmove`.

```text
setoption name Threads value 4
```

Diminishing returns past ~4–8 on most machines. Each thread uses a large stack (~8 MB).

## Move Overhead

| | |
|---|---|
| Type | spin (milliseconds) |
| Default | `10` |
| Range | 0 – 5000 |

Subtracted from remaining clock when computing how long to think. Accounts for communication lag (important for Lichess bots).

```text
setoption name Move Overhead value 100
```

## Ponder

| | |
|---|---|
| Type | check |
| Default | `false` |

Whether the engine is allowed to ponder. Full ponder flow isn't mature yet — leave `false` unless you're experimenting.

## UCI_Chess960

| | |
|---|---|
| Type | check |
| Default | `false` |

Chess960 not implemented. Option is there for UCI compatibility.

## UCI_ShowWDL

| | |
|---|---|
| Type | check |
| Default | `false` |

WDL in `info` lines not implemented yet.

## OwnBook

| | |
|---|---|
| Type | check |
| Default | `true` |

When `true`, the engine plays book moves from `Book File` at the root (if loaded).

```text
setoption name OwnBook value false
```

## Book File

| | |
|---|---|
| Type | string |
| Default | `""` (empty) |

Path to a [Polyglot](http://hgm.nubati.net/book_format.html) `.bin` opening book.

```text
setoption name Book File value Books/performance.bin
isready
```

- Relative paths depend on the **process working directory**
- Empty path = no book
- Engine stays silent on load — no confirmation line
- Invalid path = no book, search runs normally

## Book Variety

| | |
|---|---|
| Type | check |
| Default | `true` |

When `true`, book moves are chosen **weighted random** by entry weight. When `false`, always the highest-weight move.

```text
setoption name Book Variety value false
```

Good for deterministic testing.

## SyzygyPath

| | |
|---|---|
| Type | string |
| Default | `""` |

Directory containing Syzygy tablebase files (`.rtbw`, `.rtbz`). Multiple directories: separate with `;` on Windows, `:` on Unix (Fathom convention).

```text
setoption name SyzygyPath value /Users/you/tablebases/345
isready
```

What it does:

- **Root:** DTZ probe → instant `bestmove` when in tablebase
- **Search:** WDL probe → known win/loss/draw scores cut off subtrees

You need to download tablebases yourself ([Syzygy](https://syzygy-tables.info/)). 3–4–5 piece bases are enough for most practical play.

See also [Vendor/Fathom/README.md](../../Vendor/Fathom/README.md).

## Quick presets

### Local analysis (strong, no clock)

```text
setoption name Hash value 256
setoption name Threads value 4
isready
```

### Lichess bot

```text
setoption name Hash value 64
setoption name Threads value 1
setoption name Move Overhead value 100
setoption name Book File value Books/lichess.bin
setoption name SyzygyPath value /data/syzygy
isready
```

### Deterministic testing

```text
setoption name Threads value 1
setoption name OwnBook value false
setoption name Hash value 16
isready
```

Then `go depth N` for reproducible searches (same machine, same binary).

## Option timing cheat sheet

| When you change… | Effect |
|---|---|
| `Hash` | Next `go` resizes TT |
| `Threads` | Next `go` spawns helpers |
| `Book File` | Reloads immediately (silent) |
| `SyzygyPath` | Reloads immediately (silent) |
| `Move Overhead` | Next clock-based `go` |
| `OwnBook` / `Book Variety` | Next root move |

Always send `isready` after changes before `go`.
