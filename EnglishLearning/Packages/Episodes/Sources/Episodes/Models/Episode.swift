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
    public var id: String?
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

// NOTE:
// Non-sendable type '[Episode]' returned by implicitly asynchronous call to actor-isolated function
// cannot cross actor boundary
// https://forums.developer.apple.com/forums/thread/725596?answerId=749095022#749095022
extension Episode: @unchecked Sendable {}

extension Episode {
    @MainActor
    public static let dataSource: DataSource<Episode>? = {
        do {
            let modelContext = try ModelContext.default(for: Episode.self, isStoredInMemoryOnly: false)
            return DataSource<Episode>(modelContext: modelContext)
        } catch {
            return nil
        }
    }()
}
