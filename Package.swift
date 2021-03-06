// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Aether",
    products: [
        .library(name: "Aether",targets: ["Aether"])
    ],
    dependencies: [
        .package(url: "https://github.com/aestesis/Zlib.git", from:"0.1.3"),
        .package(url: "https://github.com/aestesis/Cpng", from:"2.0.2"),
        .package(url: "https://github.com/aestesis/CPango.git", .branch("master")),
        .package(url: "https://github.com/aestesis/Cfreetype.git", .branch("master")),
        .package(url: "https://github.com/aestesis/libtess.git", from:"1.0.4"),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from:"17.0.0"),
        .package(url: "https://github.com/aestesis/Cairo.git", .branch("master")),
        .package(url: "https://github.com/aestesis/Uridium.git", .branch("master"))
    ],
    targets: [
        .target(name: "Aether",dependencies: ["Uridium","SwiftyJSON","libtess","Cpng","CPango","Cairo","Zlib"])
    ]
)

