// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mlx_localllm",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "mlx-localllm", targets: ["mlx_localllm"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main")
    ],
    targets: [
        .target(
            name: "mlx_localllm",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm")
            ],
            path: ".",
            sources: ["Classes"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
