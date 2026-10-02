// Run from the repository root: swift scripts/generate-paper-colors.swift
// Sample the paper at each illustration's perimeter; never alter the artwork.
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Pour/Assets.xcassets/Cocktails")
let folders = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
for folder in folders where folder.pathExtension == "imageset" {
    let data = try Data(contentsOf: folder.appendingPathComponent("illustration.png"))
    guard let bitmap = NSBitmapImageRep(data: data) else { fatalError("Cannot read \(folder.path)") }
    // Bundled PNGs are untagged RGB. Read their components directly; converting
    // AppKit's assumed generic RGB profile to sRGB would shift the paper color.
    var channels = [[Double]](repeating: [], count: 3)
    for step in 0..<100 {
        let x = step * (bitmap.pixelsWide - 1) / 99
        let y = step * (bitmap.pixelsHigh - 1) / 99
        for (px, py) in [(x, 0), (x, bitmap.pixelsHigh - 1), (0, y), (bitmap.pixelsWide - 1, y)] {
            guard let color = bitmap.colorAt(x: px, y: py) else {
                fatalError("Cannot sample \(folder.path)")
            }
            channels[0].append(color.redComponent)
            channels[1].append(color.greenComponent)
            channels[2].append(color.blueComponent)
        }
    }
    let rgb = channels.map { $0.sorted()[$0.count / 2] }
    let id = folder.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "cocktail-", with: "")
    let destination = root.appendingPathComponent("paper-\(id).colorset")
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    let contents: [String: Any] = [
        "colors": [["idiom": "universal", "color": ["color-space": "srgb", "components": [
            "red": String(format: "%.6f", rgb[0]), "green": String(format: "%.6f", rgb[1]),
            "blue": String(format: "%.6f", rgb[2]), "alpha": "1.000000"
        ]]]], "info": ["author": "xcode", "version": 1]
    ]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        .write(to: destination.appendingPathComponent("Contents.json"))
}
