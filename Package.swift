// swift-tools-version:5.0
import PackageDescription

let name = "PMKStoreKit"

let pkg = Package(name: name)
pkg.platforms = [
  .watchOS("6.2")
]
pkg.products = [
  .library(name: name, targets: [name]),
]
pkg.swiftLanguageVersions = [.v4, .v5]
pkg.dependencies = [
  .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.0.0")
]

let target: Target = .target(name: name)
target.path = "Sources"
target.exclude = [
  "SKRequest+AnyPromise.h",
  "SKRequest+AnyPromise.m",
  "\(name).h",
]
target.dependencies = ["PromiseKit"]

pkg.targets = [target]
