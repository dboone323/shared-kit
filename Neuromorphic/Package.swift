// swift-tools-version: 5.9
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
