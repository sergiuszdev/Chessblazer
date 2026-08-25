import SwiftUI

struct ContentView: View {
    
    @Bindable var gameState = GameState()
    @State var fen = ""
    @State var vsEngine = false
    
    @State var promotionAlert = false
    @State var engineVsEngine = false
    var body: some View {
        HStack {
            Toggle("player vs engine", isOn: $vsEngine)
            Toggle("engine vs engine", isOn: $engineVsEngine)
            
            Button("Start") {
                gameState.startNewGame()
                
                if vsEngine {
                    Task {
                        await gameState.startPvE()

                    }
                                    }
                
                if engineVsEngine {
                    Task {
                        await gameState.startEvE()
                    }
                }
            }
            TextField(text: $fen) {
                Text("Input FEN here and submit (enter)")
            }.onSubmit {
                gameState.loadFenGame(fen: fen)
            }
            
        }
        
        HStack {
            VStack(alignment: .leading) {
                Button("Undone move") {
                    gameState.undoneMove()
                }
                Text("Evaluation: \(gameState.evaluation)")
                Button("test promotion") {
                    promotionAlert.toggle()
                }
            }
            ChessView(gameState: gameState)
            
            
                .popover(isPresented: $promotionAlert) {
                    Button {
                    } label: {
                        
                        if gameState.currentColorToMove == .white {
                            Image(.whiterook)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.whitequeen)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.whitebishop)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.whiteknight)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        } else {
                            Image(.blackrook)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.blackqueen)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.blackbishop)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            
                            Image(.blackknight)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        }
                        
                        
                        
                    }
                }
            
            
        }
        
    }
}

#Preview {
    ContentView()
}


