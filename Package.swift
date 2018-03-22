// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Pelican",
    products: [
			.library(name: "Pelican", targets: ["Pelican"]),
    ],
    dependencies: [
			.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
			.target(name: "Pelican", dependencies: ["SwiftyJSON"]),
    ]
)

