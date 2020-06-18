// swift-tools-version:4.2
import PackageDescription

let package = Package(name: "slack-calendar-status")

package.products = [
    .executable(name: "slack-calendar-status", targets: ["slack-calendar-status"])
]
package.dependencies = [
    .package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMajor(from: Version(6,5,0))),
    .package(url: "https://github.com/PromiseKit/PMKEventKit.git", .upToNextMajor(from: Version(4,0,0))),
    .package(url: "https://github.com/pvzig/SlackKit.git", .revision("c1a89ee")),
    .package(url: "https://github.com/emorydunn/LaunchAgent.git", .revision("df81b83"))
]
package.targets = [
    .target(name: "slack-calendar-status", dependencies: ["PromiseKit", "PMKEventKit", "SlackKit", "LaunchAgent"], path: "Sources")
]
