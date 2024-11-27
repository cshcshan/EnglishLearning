//
//  DataSource.swift
//  Core
//
//  Created by Han Chen on 2024/11/26.
//

import SwiftData

public struct DataSource<Model: PersistentModel> {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
