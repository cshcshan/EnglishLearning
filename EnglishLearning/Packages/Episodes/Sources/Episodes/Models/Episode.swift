//
//  Episode.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/22.
//

import Core
import Foundation
import SwiftData

@Model
public final class Episode {
    @Attribute(.unique) public var id: String?
    public var title: String?
    public var desc: String?
    public var date: Date?
    public var imageURLString: String?
    public var urlString: String?
    
    public init(
        id: String?,
        title: String?,
        desc: String?,
        date: Date?,
        imageURLString: String?,
        urlString: String?
    ) {
        self.id = id
        self.title = title
        self.desc = desc
        self.date = date
        self.imageURLString = imageURLString
        self.urlString = urlString
    }
}

extension Episode {
    var displayDateString: String? {
        guard let date else { return nil }
        return DateFormatter.displayDate.string(from: date)
    }
    
    var imageURL: URL? {
        URL(string: imageURLString ?? "")
    }
}

// NOTE:
// Non-sendable type '[Episode]' returned by implicitly asynchronous call to actor-isolated function
// cannot cross actor boundary
// https://forums.developer.apple.com/forums/thread/725596?answerId=749095022#749095022
extension Episode: @unchecked Sendable {}

// `Episode` conforms to `Equatable` for unit tests
extension Episode: Equatable {
    public static func == (lhs: Episode, rhs: Episode) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.desc == rhs.desc
            && lhs.date == rhs.date
            && lhs.imageURLString == rhs.imageURLString
            && lhs.urlString == rhs.urlString
    }
}

extension Episode {
    @MainActor
    public static let dataSource: DataSource<Episode>? = {
        do {
            return try DataSource<Episode>(for: Episode.self, isStoredInMemoryOnly: false)
        } catch {
            return nil
        }
    }()
}
