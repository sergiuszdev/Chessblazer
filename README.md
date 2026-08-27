
# Chessblazer

UCI chess engine written in Swift. Play it on [Lichess](https://lichess.org/@/TheChessblazer).

**Want to use it in your app?** → [docs/](docs/README.md) (Swift library + UCI subprocess guides)

Build the UCI binary with:

```
swift build -c release --product ChessblazerUCI
```

# Engine
Check it out on [Lichess](https://lichess.org/@/TheChessblazer)
## Current state
<img width="720" height="840" alt="lichess-game-BoJ1PFjF-white" src="https://github.com/user-attachments/assets/a8a1bc98-23af-44ca-a4ec-19aa0f65e023" />


<i>it's a bit smarter now — opening book, syzygy tablebases, and it even once beat stockfish level 1</i>

## Game logic
### Implemented
- generating moves using bitboard
- hashing magic bitboards
- checks
- pins
- xrays
- castling
- pawn promotions
- en passant

### Not implemented yet

## AI
### Implemented
- Alpha-Beta Pruning
- Quiescence search
- Move Ordering (tt move, killers, history)
- Iterative deepening
- Transposition Table
- Zobrist hashing
- Null move pruning
- Late move reductions
- Aspiration windows
- Reverse futility / razoring / futility pruning
- Lazy SMP (`Threads` UCI option)
- Polyglot opening book (`Book File`, `OwnBook`, `Book Variety`)
- Syzygy tablebases (WDL in search, DTZ at root via `SyzygyPath`)
- Evaluation with game phase, pawn structure (passed pawns), bishop pair, rook files, mobility and king safety
### Not implemented yet
- NNUE evaluation

## UCI
### Implemented
- UCI protocol
- talking to Lichess (it already played some games there)
- `Hash`, `Threads`, `Move Overhead`, `Book File`, `SyzygyPath` and the usual UCI options

Point `Book File` at a polyglot `.bin` and `SyzygyPath` at a folder of `.rtbw` / `.rtbz` files if you want those.

## Next steps
- NNUE evaluation

## Perft results
<a href="https://www.chessprogramming.org/Perft_Results">I use this data to compare with my results</a>

Performance tests are validated through unit tests implemented with the Swift Testing framework.
To execute the performance tests, run the 'Performance Tests' suite
### From Initial Position
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>0</td>
    <td>1</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>1</td>
    <td>20</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>400</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>8902</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>197281</td>
    <td>✅</td>
  </tr>
    <tr>
    <td>5</td>
    <td>4865609</td>
    <td>✅</td>
  </tr>
    <tr>
    <td>6</td>
    <td>119060324</td>
    <td>✅</td>
  </tr>
</table>

### Position 2 (Kiwipete)
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>1</td>
    <td>48</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>2039</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>97862</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>4085603</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>5</td>
    <td>193690690</td>
    <td>✅</td>
  </tr>
</table>

### Position 3
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>1</td>
    <td>14</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>191</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>2812</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>43238</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>5</td>
    <td>674624</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>6</td>
    <td>11030083</td>
    <td>✅</td>
  </tr>
</table>

### Position 4
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>1</td>
    <td>6</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>264</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>9467</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>422333</td>
    <td>✅</td>
  </tr>
    <tr>
    <td>5</td>
    <td>15833292</td>
    <td>✅</td>
  </tr>
</table>

### Position 5
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>1</td>
    <td>44</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>1486</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>62379</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>2103487</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>5</td>
    <td>89941194</td>
    <td>✅</td>
  </tr>
</table>

### Position 6
<table>
   <tr>
    <th>Depth</th>
    <th>Nodes</th>
    <th>Passed</th>
  </tr>
  <tr>
    <td>1</td>
    <td>46</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>2</td>
    <td>2079</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>3</td>
    <td>89890</td>
    <td>✅</td>
  </tr>
  <tr>
    <td>4</td>
    <td>3894594</td>
    <td>✅</td>
  </tr>
</table>


# GUI

App is in a separate repo: [chessblazer-app](https://github.com/sergiuszdev/chessblazer-app).

