// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notchkin",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Notchkin", targets: ["Notchkin"])],
    targets: [.executableTarget(name: "Notchkin")]
)
