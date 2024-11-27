//
//  ModelContainer+Extensions.swift
//  Core
//
//  Created by Han Chen on 2024/11/27.
//

import Foundation
import SwiftData

extension ModelContext {
    @MainActor
    public static func `default`<Model: PersistentModel>(
        for type: Model.Type,
        isStoredInMemoryOnly: Bool
    ) throws -> ModelContext {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        let modelContainer = try ModelContainer(for: type.self, configurations: modelConfiguration)
        return modelContainer.mainContext
    }
}
