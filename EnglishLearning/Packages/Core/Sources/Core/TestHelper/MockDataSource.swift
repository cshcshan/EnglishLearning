//
//  MockDataSource.swift
//  Core
//
//  Created by Han Chen on 2024/12/2.
//

import Foundation
import SwiftData

public final class MockDataSource<Model: PersistentModel>: DataProvideable {
    public typealias FetchResult = Result<[Model], DummyError>
    
    var fetchResult: FetchResult?
    public private(set) var fetchCount = 0
    
    public init(fetchResult: FetchResult? = nil) {
        self.fetchResult = fetchResult
    }
    
    public func fetch(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        fetchCount += 1
        guard let fetchResult else { return [] }

        switch fetchResult {
        case let .success(models):
            return models
        case let .failure(error):
            throw error
        }
    }
    
    public func add(_ models: [Model]) throws { }
    
    public func delete(_ models: [Model]) throws { }
}
