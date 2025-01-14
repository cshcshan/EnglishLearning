//
//  DataSource.swift
//  Core
//
//  Created by Han Chen on 2024/11/26.
//

import SwiftData

public typealias SendablePersistentModel = PersistentModel & Sendable

public protocol DataProvideable: Sendable {
    func fetch<Model: SendablePersistentModel>(_ descriptor: FetchDescriptor<Model>) async throws -> [Model]
    func add<Model: SendablePersistentModel>(_ models: [Model]) async throws
    func delete<Model: SendablePersistentModel>(_ models: [Model]) async throws
}

@ModelActor
public actor DataSource: DataProvideable {
    public func fetch<Model: SendablePersistentModel>(
        _ descriptor: FetchDescriptor<Model>
    ) async throws -> [Model] {
        try modelContext.fetch(descriptor)
    }
    
    public func add<Model: SendablePersistentModel>(_ models: [Model]) async throws {
        models.forEach { modelContext.insert($0) }
        try modelContext.save()
    }
    
    public func delete<Model: SendablePersistentModel>(_ models: [Model]) async throws {
        models.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
