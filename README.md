# UCI-compatible Chess Engine fully written in Swift with dedicated GUI in SwiftUI
# Engine
Check it out on [Lichess](https://lichess.org/@/TheChessblazer)
## Current state

## Old state showcase (me vs engine)
<img src = "https://raw.githubusercontent.com/SzymonSergiusz/Chessblazer/main/res/showcase2.gif" alt="showcase">
<i>it's little smarter now, it even once beat stockfish level 1</i>

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
- Evaluation with game phase, pawn structure, mobility and king safety
### Not implemented yet
- Opening book

## UCI
### Implemented
- UCI protocol
- talking to Lichess (it already played some games there)

## Next steps
- Opening book

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


# GUI
## UI
### Implemented
- basic game (based on engine)
- starting new game
- player vs engine [check engine in left corner]
- engine vs engine
- loading game from fen notation
- undoing moves
### Not yet implemented
- choosing piece for pawn's promotion
- switching pov
- choosing player's color
- making custom positions
- and many more (right now I don't plan anything for GUI as I focus on engine) 
