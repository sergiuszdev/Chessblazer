# Getting started

## Requirements

- macOS 14+ or iOS 17+ (see `Package.swift`)
- Swift 6 toolchain
- Xcode 16+ (if you use the `.xcodeproj`) or Swift Package Manager on the command line

## Clone and build

```bash
git clone https://github.com/SzymonSergiusz/Chessblazer.git
cd Chessblazer
swift build -c release --product ChessblazerUCI
```

The UCI binary ends up at:

```
.build/release/ChessblazerUCI
```

Run it:

```bash
.build/release/ChessblazerUCI
```

Type `uci` and press Enter — you should get `id name Chessblazer …` and `uciok`.

## Add as a Swift package dependency

In your app's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SzymonSergiusz/Chessblazer.git", branch: "main"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "Chessblazer", package: "Chessblazer"),
        ]
    ),
]
```

Then `import Chessblazer` in your source files.

### Local path dependency (while developing)

```swift
.package(path: "../Chessblazer"),
```

## Xcode project

Open `Chessblazer.xcodeproj` if you want to hack on the engine itself or run tests.

- **Chessblazer** — the library target
- **ChessblazerUCI** — the UCI executable
- **ChessblazerEngineTests** — unit tests (Swift Testing)

## Optional assets

These are not bundled — you provide your own files and point the engine at them via UCI options.

| Asset | UCI option | Format |
|---|---|---|
| Opening book | `Book File` | Polyglot `.bin` |
| Tablebases | `SyzygyPath` | Folder of `.rtbw` / `.rtbz` files |

See [reference/uci-options.md](reference/uci-options.md) for details.

## Next

- Swift app → [integration/swift-library.md](integration/swift-library.md)
- Subprocess / bot → [integration/uci-subprocess.md](integration/uci-subprocess.md)
