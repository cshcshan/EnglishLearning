//
//  MockDataSource.swift
//  Core
//
//  Created by Han Chen on 2024/12/2.
//

import Foundation
import SwiftData

public final class MockDataSource: DataProvideable {
    public typealias FetchResult = Result<[any PersistentModel], DummyError>
    
    var fetchResult: FetchResult?
    public private(set) var fetchCount = 0
    
    public init(fetchResult: FetchResult? = nil) {
        self.fetchResult = fetchResult
    }
    
    public func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        fetchCount += 1
        guard let fetchResult else { return [] }

        switch fetchResult {
        case let .success(models):
            return models as? [Model] ?? []
        case let .failure(error):
            throw error
        }
    }
    
    public func add<Model: PersistentModel>(_ models: [Model]) throws {}
    
    public func delete<Model: PersistentModel>(_ models: [Model]) throws {}
}
