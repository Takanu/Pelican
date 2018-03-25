// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Pelican",
    products: [
			.library(name: "Pelican", targets: ["Pelican"]),
    ],
    dependencies: [
			.package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .upToNextMajor(from: "17.0.0"))
    ],
    targets: [
			.target(name: "Pelican", dependencies: ["SwiftyJSON"]),
    ]
)

