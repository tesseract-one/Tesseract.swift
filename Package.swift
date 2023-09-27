// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let useLocalBinary = true

var package = Package(
    name: "Tesseract",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "TesseractClient",
            targets: ["TesseractClient"]),
        .library(
            name: "TesseractClientTransports",
            targets: ["TesseractClientTransports"]),
        .library(
            name: "TesseractService",
            targets: ["TesseractService"]),
        .library(
            name: "TesseractServiceTransports",
            targets: ["TesseractServiceTransports"]),
        .library(
            name: "TesseractShared",
            targets: ["TesseractShared"]),
        .library(
            name: "TesseractUtils",
            targets: ["TesseractUtils"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TesseractClient",
            dependencies: ["TesseractClientTransports", "CTesseractBin"]),
        .target(
            name: "TesseractService",
            dependencies: ["TesseractServiceTransports", "CTesseractBin"]),
        .target(
            name: "TesseractClientTransports",
            dependencies: ["TesseractUtils", "TesseractShared", "CTesseract"]),
        .target(
            name: "TesseractServiceTransports",
            dependencies: ["TesseractUtils", "TesseractShared", "CTesseract"]),
        .target(
            name: "TesseractShared",
            dependencies: ["TesseractUtils", "CTesseract"]),
        .target(
            name: "TesseractUtils",
            dependencies: ["CTesseract"]),
        .target(name: "CTesseract", dependencies: []),
        useLocalBinary
            ? .binaryTarget(name: "CTesseractBin", path: "CTesseractBin.xcframework")
            : .binaryTarget(name: "CTesseractBin", url: "", checksum: "")
    ]
)
