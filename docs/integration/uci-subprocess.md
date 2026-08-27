# UCI subprocess integration

Use this when your app is **not** Swift, or you want the full engine (book, syzygy, clocks, threads).

Chessblazer speaks [UCI](https://www.chessprogramming.org/UCI) over stdin/stdout.

## Build and run

```bash
swift build -c release --product ChessblazerUCI
./.build/release/ChessblazerUCI
```

The process reads lines from stdin and writes responses to stdout (one line per message, flushed immediately).

## Minimal client (pseudocode)

```
spawn("./ChessblazerUCI")
write("uci\n")
wait for line containing "uciok"

write("isready\n")
wait for "readyok"

write("ucinewgame\n")
write("position startpos\n")
write("go depth 8\n")
read lines until one starts with "bestmove"
```

Full session: [examples/uci-session.txt](../examples/uci-session.txt).

## Lifecycle

```
┌─────────┐     uci      ┌────────┐
│  Your   │ ──────────►  │ Chess- │
│  app    │ ◄──────────  │ blazer │
└─────────┘    uciok     └────────┘
     │
     │  setoption … (optional, repeat)
     │  isready  →  readyok
     │
     │  ucinewgame
     │  position …
     │  go …
     │  ◄── info … (zero or more)
     │  ◄── bestmove e2e4
     │
     │  position … moves …
     │  go …
     │     …
     │
     │  quit
     ▼
```

## Spawning from different languages

### Python

```python
import subprocess

proc = subprocess.Popen(
    [".build/release/ChessblazerUCI"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1,
)

def send(cmd: str) -> None:
    proc.stdin.write(cmd + "\n")
    proc.stdin.flush()

def read_until(prefix: str) -> str:
    while True:
        line = proc.stdout.readline().strip()
        if line.startswith(prefix):
            return line

send("uci")
while True:
    line = proc.stdout.readline().strip()
    if line == "uciok":
        break

send("isready")
read_until("readyok")

send("ucinewgame")
send("position startpos")
send("go movetime 1000")
bestmove = read_until("bestmove")
print(bestmove)  # bestmove e2e4

send("quit")
proc.wait()
```

### Node.js

```javascript
import { spawn } from "node:child_process";

const engine = spawn(".build/release/ChessblazerUCI");
const lines = [];

engine.stdout.on("data", (chunk) => {
  for (const line of chunk.toString().split("\n").filter(Boolean)) {
    lines.push(line);
    if (line.startsWith("bestmove")) console.log(line);
  }
});

function send(cmd) {
  engine.stdin.write(cmd + "\n");
}

send("uci");
// wait for uciok in your parser, then:
send("isready");
send("position startpos");
send("go depth 6");
```

### Swift (subprocess)

If you don't want `import Chessblazer` in-process, spawn the binary the same way any UCI GUI would — `Process` + pipes. Same commands as above.

## Important rules

1. **After every `setoption`, send `isready` and wait for `readyok`** before searching. The engine loads books/tablebases during option changes.

2. **One search at a time.** Don't send a new `go` until you got `bestmove` (or send `stop` first).

3. **Engine stays quiet on `setoption`** — no `info string` acks. That's intentional (lichess-bot treats stray info as errors).

4. **Parse `bestmove` from the start of the line** — you may get `info depth …` lines first during search.

5. **`bestmove 0000`** means no legal move (game over). Your GUI should handle that.

## Position commands

```text
position startpos
position startpos moves e2e4 e7e5 g1f3
position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
position fen <fen> moves e2e4 e7e5
```

Unknown moves in the `moves` list produce `info string unknown move <notation>` but don't crash the engine.

## Go commands

Chessblazer understands standard UCI `go` tokens:

| Token | Example | Meaning |
|---|---|---|
| `depth` | `go depth 12` | Search to depth 12 |
| `movetime` | `go movetime 500` | Search ~500 ms |
| `wtime` / `btime` | `go wtime 60000 btime 60000` | Clock-aware (ms remaining) |
| `winc` / `binc` | `go wtime 60000 winc 1000 btime 60000 binc 1000` | With increment |
| `movestogo` | `go wtime 30000 movestogo 20` | Moves until time control |
| `infinite` | `go infinite` | Search until `stop` |
| `nodes` | parsed, not enforced yet | — |
| `mate` | parsed, not enforced yet | — |

If you send `go` with no time info and no depth, the engine defaults to about **1 second** per move.

## Stopping a search

```text
stop
```

Send this when the user moves during engine think, or you need to abort. You'll get `bestmove …` shortly after.

## Opening book and syzygy at root

Before search starts, the engine checks (in order):

1. **Opening book** — if `OwnBook` is on and `Book File` points to a valid polyglot `.bin`
2. **Syzygy DTZ** — if `SyzygyPath` is set and the position is in tablebases

If either hits, you get `bestmove` immediately with no `info` lines.

## Bundling the binary in your app

- **macOS:** ship `ChessblazerUCI` in your `.app/Contents/MacOS/` or `Resources/`, mark executable
- **iOS:** subprocess UCI is awkward (sandbox). Use the Swift library instead.
- **Linux:** same as macOS if you cross-compile

## Further reading

- [uci-protocol.md](../reference/uci-protocol.md) — every command in order
- [uci-options.md](../reference/uci-options.md) — Hash, Threads, book, syzygy
