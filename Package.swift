// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notchpop",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Notchpop", targets: ["Notchpop"])],
    targets: [.executableTarget(name: "Notchpop")]
)
