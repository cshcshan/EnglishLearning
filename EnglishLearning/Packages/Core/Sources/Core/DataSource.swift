//
//  DataSource.swift
//  Core
//
//  Created by Han Chen on 2024/11/26.
//

import SwiftData

public protocol DataProvideable {
    func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [Model]
    func add<Model: PersistentModel>(_ models: [Model]) throws
    func delete<Model: PersistentModel>(_ models: [Model]) throws
}

public struct DataSource: DataProvideable {
    // NOTE:
    // Although we don't access `modelContainer` in `DataSource` except `init()`, we still need to store
    // it globally, otherwise, it will be released after `init()`
    public let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @MainActor
    public init(with modelContainer: ModelContainer) throws {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    public func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }
    
    public func add<Model: PersistentModel>(_ models: [Model]) throws {
        models.forEach { modelContext.insert($0) }
        try modelContext.save()
    }
    
    public func delete<Model: PersistentModel>(_ models: [Model]) throws {
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
