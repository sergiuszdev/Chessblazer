#if SWIFT_PACKAGE
import Chessblazer
#endif
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
