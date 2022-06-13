// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-xml-parser",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "XMLParser",
            targets: ["XMLParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JaapWijnen/swift-parsing", .branch("pipe-end-printer")),
        //.package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.9.2"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
