//
//  EngineApp.swift
//  Chessblazer
//
//  Created by sergiusz on 25/07/2024.
//

import Foundation

@main
struct EngineApp {
    static func main() {
        let engine = Engine()
        while !engine.quit {
            if let input = readLine() {
                engine.processInput(command: input)
            }
        }
    }
}
