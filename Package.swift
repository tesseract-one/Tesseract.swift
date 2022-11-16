// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "Tesseract",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "TesseractClient",
            targets: ["TesseractClient"]),
        .library(
            name: "TesseractService",
            targets: ["TesseractService"]),
        .library(
            name: "TesseractUtils",
            targets: ["TesseractUtils"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TesseractClient",
            dependencies: ["TesseractUtils", "CTesseractClient"]),
        .target(
            name: "TesseractService",
            dependencies: ["TesseractUtils", "CTesseractService"]),
        .target(
            name: "TesseractUtils",
            dependencies: ["CTesseractUtils"]),
        .systemLibrary(name: "CTesseractUtils"),
        .systemLibrary(name: "CTesseractClient"),
        .systemLibrary(name: "CTesseractService")
    ]
)
