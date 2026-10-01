// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PourCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "PourCore", targets: ["PourCore"])],
    targets: [
        .target(name: "PourCore", path: "Sources/PourCore"),
        .testTarget(name: "PourCoreTests", dependencies: ["PourCore"], path: "Tests/PourCoreTests")
    ]
)
