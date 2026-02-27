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
        .package(url: "https://github.com/MacPaw/OpenAI", from: "0.2.5"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                "OpenAI",
                "GRDB",
                "KeychainAccess"
            ],
            path: "Sources/AltWisprFlow"
        )
    ]
)
