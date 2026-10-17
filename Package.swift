// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FluidNCConfig",
    products: [
        .library(name: "FluidNCConfig", targets: ["FluidNCConfig"])
    ],
    targets: [
        .target(name: "FluidNCConfig"),
        .testTarget(name: "FluidNCConfigTests", dependencies: ["FluidNCConfig"]),
    ]
)
