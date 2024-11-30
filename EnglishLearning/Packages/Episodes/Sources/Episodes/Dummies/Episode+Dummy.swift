//
//  Episode+Dummy.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/29.
//

import Foundation

#if DEBUG

extension Episode {
    static func dummy(withIndex index: Int) -> Episode {
        Episode(
            id: "\(index)",
            title: "title \(index)",
            desc: "desc \(index)",
            date: nil,
            imageURLString: "imageURLString \(index)",
            urlString: "urlString \(index)"
        )
    }
}

extension [Episode] {
    static func dummy(withAmount amount: Int) -> [Episode] {
        guard amount > 0 else { return [] }
        return (0..<amount).map(Episode.dummy)
    }
}

#endif
