//
//  ModelContainer+Extension.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/15.
//

import Foundation
import SwiftData

#if DEBUG || TEST

extension ModelContainer {
    @MainActor
    static func mock(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([Episode.self, EpisodeDetail.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        return try ModelContainer(for: schema, configurations: modelConfiguration)
    }
}

#endif
