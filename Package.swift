// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Undertitle",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "UndertitleKit", targets: ["UndertitleKit"]),
        .executable(name: "undertitle", targets: ["undertitle-cli"]),
        .executable(name: "undertitle-mcp", targets: ["undertitle-mcp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.0"),
    ],
    targets: [
        // Shared core — the SAME source files the macOS app compiles, exposed as
        // a library so the CLI and MCP server can reuse the exact pipeline.
        .target(
            name: "UndertitleKit",
            path: "undertitle",
            sources: ["Models", "Services"]
        ),
        // Command-line interface.
        .executableTarget(
            name: "undertitle-cli",
            dependencies: [
                "UndertitleKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/cli"
        ),
        // MCP server so agents can transcribe videos as a tool.
        .executableTarget(
            name: "undertitle-mcp",
            dependencies: [
                "UndertitleKit",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/mcp"
        ),
    ]
)
