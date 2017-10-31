// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Pelican",
    products: [
			.library(name: "Pelican", targets: ["Pelican"]),
    ],
    dependencies: [
			.package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
			.package(url: "https://github.com/vapor/fluent-provider.git", .upToNextMajor(from: "1.2.0")),
    ],
    targets: [
			.target(name: "Pelican", dependencies: ["Vapor", "FluentProvider"]),
    ]
)

