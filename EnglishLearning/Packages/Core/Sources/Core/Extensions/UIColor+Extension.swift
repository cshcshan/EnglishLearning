//
//  UIColor+Extension.swift
//  Core
//
//  Created by Han Chen on 2024/12/11.
//

import UIKit
extension UIColor {

    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0

        return String(format: "#%06x", rgb)
    }

    convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") {
            scanner.currentIndex = hexString.index(hexString.startIndex, offsetBy: 1)
        }
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask

        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }

    convenience init(rgb: (CGFloat, CGFloat, CGFloat)) {
        self.init(red: rgb.0/255.0, green: rgb.1/255.0, blue: rgb.2/255.0, alpha: 1)
    }

    convenience init(rgba: (CGFloat, CGFloat, CGFloat, CGFloat)) {
        self.init(red: rgba.0/255.0, green: rgba.1/255.0, blue: rgba.2/255.0, alpha: rgba.3)
    }
}
