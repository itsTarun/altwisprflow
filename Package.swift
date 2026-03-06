// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AltWisprFlow",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "AltWisprFlow",
            targets: ["AltWisprFlow"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.5"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.30.0"),
        .package(url: "https://github.com/Blaizzy/mlx-audio-swift.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXAudio", package: "mlx-audio-swift")
            ],
            path: "Sources/AltWisprFlow"
        )
    ]
)
