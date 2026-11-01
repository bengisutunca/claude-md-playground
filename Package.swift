// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TMDBApp",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TMDBApp", targets: ["TMDBApp"])
    ],
    targets: [
        .target(
            name: "TMDBApp",
            path: "Sources/TMDBApp"
        ),
        .testTarget(
            name: "TMDBAppTests",
            dependencies: ["TMDBApp"],
            path: "Tests/TMDBAppTests",
            resources: [.copy("Fixtures")]
        )
    ],
    swiftLanguageModes: [.v5]
)
