#!/usr/bin/env swift
import AppKit
import Foundation

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Background with gradient
let context = NSGraphicsContext.current!.cgContext
let colors = [NSColor.systemBlue.cgColor, NSColor.systemIndigo.cgColor]
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil)!

context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// Clipboard shape
let clipboardRect = NSRect(x: size * 0.2, y: size * 0.15, width: size * 0.6, height: size * 0.7)
let clipboardPath = NSBezierPath(roundedRect: clipboardRect, xRadius: size * 0.05, yRadius: size * 0.05)

// Clipboard body (white)
NSColor.white.setFill()
clipboardPath.fill()

// Clipboard top (clip part)
let clipRect = NSRect(x: size * 0.35, y: size * 0.75, width: size * 0.3, height: size * 0.15)
let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.03, yRadius: size * 0.03)
NSColor.systemGray.setFill()
clipPath.fill()

// Lines on clipboard (representing text)
NSColor.systemGray.withAlphaComponent(0.3).setStroke()
let lineWidth = size * 0.015
let linePath = NSBezierPath()
linePath.lineWidth = lineWidth

// Draw 4 lines
for i in 0..<4 {
    let y = size * 0.3 + CGFloat(i) * size * 0.1
    linePath.move(to: NSPoint(x: size * 0.3, y: y))
    linePath.line(to: NSPoint(x: size * 0.7, y: y))
}
linePath.stroke()

// Copy symbol (overlay)
let copySymbol = "📋"
let font = NSFont.systemFont(ofSize: size * 0.4, weight: .bold)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.systemBlue
]
let symbolSize = copySymbol.size(withAttributes: attributes)
let symbolRect = NSRect(
    x: (size - symbolSize.width) / 2,
    y: (size - symbolSize.height) / 2 - size * 0.05,
    width: symbolSize.width,
    height: symbolSize.height
)
copySymbol.draw(in: symbolRect, withAttributes: attributes)

image.unlockFocus()

// Save as PNG
let tiffData = image.tiffRepresentation!
let bitmapImage = NSBitmapImageRep(data: tiffData)!
let pngData = bitmapImage.representation(using: .png, properties: [:])!

let outputPath = CommandLine.arguments[1]
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Icon generated: \(outputPath)")

