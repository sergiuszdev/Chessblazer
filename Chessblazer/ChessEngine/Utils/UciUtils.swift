//
//  UciUtils.swift
//  Chessblazer
//
//  Created by sergiusz on 05/10/2024.
//

import Foundation

struct UciGoInput {
    var ponder = false
    var whiteTime: Int?
    var blackTime: Int?
    var whiteIncrementTime: Int?
    var blackIncrementTime: Int?
    var movesToGo: Int?
    var depth: Int?
    var nodes: Int?
    var searchMateIn: Int?
    var searchMoveTime: Int?
    var infinite = false
    
    static func parse(from command: String) -> UciGoInput {
        var result = UciGoInput()
        let tokens = command.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        var index = tokens.first == "go" ? 1 : 0
        
        func takeInt() -> Int? {
            index += 1
            guard index < tokens.count else { return nil }
            return Int(tokens[index])
        }
        
        while index < tokens.count {
            switch tokens[index] {
            case "ponder":
                result.ponder = true
            case "infinite":
                result.infinite = true
            case "wtime":
                result.whiteTime = takeInt()
            case "btime":
                result.blackTime = takeInt()
            case "winc":
                result.whiteIncrementTime = takeInt()
            case "binc":
                result.blackIncrementTime = takeInt()
            case "movestogo":
                result.movesToGo = takeInt()
            case "depth":
                result.depth = takeInt()
            case "nodes":
                result.nodes = takeInt()
            case "mate":
                result.searchMateIn = takeInt()
            case "movetime":
                result.searchMoveTime = takeInt()
            default:
                break
            }
            index += 1
        }
        
        return result
    }
}

struct SearchLimits {
    let maxDepth: Int
    let allocatedTime: TimeInterval?
    
    static let defaultMoveTime: TimeInterval = 1.0
    static let maxSearchDepth = 64
    
    static func from(go: UciGoInput, sideToMove: Piece.Color, moveOverheadMs: Int = 10) -> SearchLimits {
        let maxDepth = min(max(go.depth ?? maxSearchDepth, 1), maxSearchDepth)
        
        if go.infinite || go.ponder {
            return SearchLimits(maxDepth: go.depth ?? maxSearchDepth, allocatedTime: nil)
        }
        
        if let moveTime = go.searchMoveTime, moveTime > 0 {
            return SearchLimits(maxDepth: go.depth ?? maxSearchDepth, allocatedTime: TimeInterval(moveTime) / 1000.0)
        }
        
        let remaining: Int?
        let increment: Int
        if sideToMove == .white {
            remaining = go.whiteTime
            increment = go.whiteIncrementTime ?? 0
        } else {
            remaining = go.blackTime
            increment = go.blackIncrementTime ?? 0
        }
        
        if let remaining, remaining > 0 {
            let movesToGo = max(go.movesToGo ?? 30, 1)
            let usable = max(remaining - moveOverheadMs, 1)
            var allocatedMs = usable / movesToGo + increment / 2
            allocatedMs = min(allocatedMs, usable / 2)
            allocatedMs = min(allocatedMs, max(usable - 20, 1))
            allocatedMs = max(allocatedMs, 50)
            allocatedMs = min(allocatedMs, usable)
            return SearchLimits(maxDepth: go.depth ?? maxSearchDepth, allocatedTime: TimeInterval(allocatedMs) / 1000.0)
        }
        
        if go.depth != nil {
            return SearchLimits(maxDepth: maxDepth, allocatedTime: nil)
        }
        
        return SearchLimits(maxDepth: maxSearchDepth, allocatedTime: defaultMoveTime)
    }
}

struct UciOption {
    let name: String
    let type: String
    let defaultValue: String
    var min: Int? = nil
    var max: Int? = nil
    
    var advertisement: String {
        switch type {
        case "spin":
            return "option name \(name) type spin default \(defaultValue) min \(min ?? 0) max \(max ?? 0)"
        case "check":
            return "option name \(name) type check default \(defaultValue)"
        default:
            return "option name \(name) type string default \(defaultValue)"
        }
    }
}

struct EngineUciOptions {
    static let advertised: [UciOption] = [
        UciOption(name: "Hash", type: "spin", defaultValue: "16", min: 1, max: 4096),
        // Single-threaded search; max is advertised so GUIs can set Threads: 4.
        UciOption(name: "Threads", type: "spin", defaultValue: "1", min: 1, max: 256),
        UciOption(name: "Ponder", type: "check", defaultValue: "false"),
        UciOption(name: "Move Overhead", type: "spin", defaultValue: "10", min: 0, max: 5000),
        UciOption(name: "UCI_Chess960", type: "check", defaultValue: "false"),
        UciOption(name: "UCI_ShowWDL", type: "check", defaultValue: "false"),
        UciOption(name: "SyzygyPath", type: "string", defaultValue: "")
    ]
    
    private var values: [String: String]
    
    init() {
        values = Dictionary(uniqueKeysWithValues: Self.advertised.map { ($0.name.lowercased(), $0.defaultValue) })
    }
    
    mutating func set(name: String, value: String) {
        values[name.lowercased()] = value
    }
    
    var moveOverheadMs: Int {
        max(Int(values["move overhead"] ?? "") ?? 10, 0)
    }
}

func parseUciSetOption(args: [String]) -> (name: String, value: String)? {
    guard args.count >= 3, args[0] == "setoption", args[1] == "name" else { return nil }
    var index = 2
    var nameParts: [String] = []
    while index < args.count && args[index] != "value" {
        nameParts.append(args[index])
        index += 1
    }
    let name = nameParts.joined(separator: " ")
    guard !name.isEmpty else { return nil }
    var value = ""
    if index < args.count, args[index] == "value" {
        value = args[(index + 1)...].joined(separator: " ")
    }
    return (name, value)
}
