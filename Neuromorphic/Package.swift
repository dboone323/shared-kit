// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Neuromorphic",
    products: [
        .executable(name: "NeuromorphicDemo", targets: ["NeuromorphicDemo"]),
    ],
    targets: [
        .executableTarget(
            name: "NeuromorphicDemo",
            dependencies: []
        ),
    ]
)
