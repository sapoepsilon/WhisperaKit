// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperaKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WhisperaKit", targets: ["WhisperaKit"]),
        .executable(name: "whispera", targets: ["whispera"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", .upToNextMinor(from: "2.29.1")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "WhisperaKit",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "whispera",
            dependencies: [
                "WhisperaKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "WhisperaKitTests",
            dependencies: ["WhisperaKit"]
        )
    ]
)
