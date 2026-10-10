// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cafeine",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Cafeine", path: "Sources/Cafeine"),
        // Comme Epigraphe : la cible de test dépend de l'exécutable, XCTest est
        // dans la toolchain, rien à installer.
        .testTarget(name: "CafeineTests", dependencies: ["Cafeine"], path: "Tests/CafeineTests"),
    ]
)
