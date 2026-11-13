// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CondoValuationKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "CondoValuationKit", targets: ["CondoValuationKit"])
    ],
    targets: [
        .target(name: "CondoValuationKit"),
        .testTarget(name: "CondoValuationKitTests", dependencies: ["CondoValuationKit"])
    ]
)
