//
//  DataSource.swift
//  Core
//
//  Created by Han Chen on 2024/11/26.
//

import SwiftData

public struct DataSource<Model: PersistentModel> {
    // NOTE:
    // Although we don't access `modelContainer` in `DataSource` except `init()`, we still need to store
    // it globally, otherwise, it will be released after `init()`
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @MainActor
    public init(for type: Model.Type, isStoredInMemoryOnly: Bool) throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.modelContainer = try ModelContainer(for: type.self, configurations: modelConfiguration)
        self.modelContext = modelContainer.mainContext
    }
    
    public func fetch(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }
    
    public func add(_ models: [Model]) throws {
        models.forEach { modelContext.insert($0) }
        try modelContext.save()
    }
    
    public func delete(_ models: [Model]) throws {
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
