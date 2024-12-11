//
//  AttributedString+Extension.swift
//  Core
//
//  Created by Han Chen on 2024/12/11.
//

import UIKit

extension AttributedString {
    public static func html(
        _ htmlString: String,
        fontName: String? = nil,
        fontSize: String? = nil,
        fontColor: UIColor? = nil,
        backgroundColor: UIColor? = nil
    ) throws -> AttributedString? {
        let attributedString = try NSAttributedString.html(
            htmlString,
            fontName: fontName,
            fontSize: fontSize,
            fontColor: fontColor,
            backgroundColor: backgroundColor
        )
        guard let attributedString else { return nil }
        return AttributedString(attributedString)
    }
}

extension NSAttributedString {
    static func html(
        _ htmlString: String,
        fontName: String? = nil,
        fontSize: String? = nil,
        fontColor: UIColor? = nil,
        backgroundColor: UIColor? = nil
    ) throws -> NSAttributedString? {
        var htmlString = htmlString.replacingOccurrences(of: "\n", with: "<br/>")
        
        var style = ""
        if let fontName {
            style += "font-family:'\(fontName)';"
        }
        if let fontSize {
            style += "font-size:\(fontSize)px;"
        }
        if let fontColor {
            style += "color:\(fontColor.hexString);"
        }
        if let backgroundColor {
            style += "background-color:\(backgroundColor.hexString);"
        }
        
        if !style.isEmpty {
            htmlString = "<style>body{\(style)}</style>\(htmlString)"
        }
        
        guard let data = htmlString.data(using: .utf8) else { return nil }

        return try NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }
}
