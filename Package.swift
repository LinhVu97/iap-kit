// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "FidraIAP",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "FidraIAP",
            targets: ["FidraIAP"]),
    ],
    targets: [
        .target(
            name: "FidraIAP")
    ]
)
