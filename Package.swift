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
        .package(name: "OpenAI", url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.5"),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(name: "KeychainAccess", url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "GRDB", package: "GRDB"),
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ],
            path: "Sources/AltWisprFlow"
        )
    ]
)
