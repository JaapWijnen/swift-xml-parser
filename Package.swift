// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-xml-parser",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "XMLParser",
            targets: ["XMLParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.10.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "XMLParser",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "Collections", package: "swift-collections"),
            ]),
        .testTarget(
            name: "XMLParserTests",
            dependencies: [
                "XMLParser",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]),
    ]
)
