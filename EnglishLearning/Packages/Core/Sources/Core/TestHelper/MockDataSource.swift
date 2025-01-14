//
//  MockDataSource.swift
//  Core
//
//  Created by Han Chen on 2024/12/2.
//

import Foundation
import SwiftData

public actor MockDataSource: DataProvideable {
    public typealias FetchResult = Result<[any SendablePersistentModel], DummyError>
    
    var fetchResult: FetchResult?
    public private(set) var fetchCount = 0
    
    public init(fetchResult: FetchResult? = nil) {
        self.fetchResult = fetchResult
    }
    
    public func fetch<Model: SendablePersistentModel>(
        _ descriptor: FetchDescriptor<Model>
    ) throws -> [Model] {
        fetchCount += 1
        guard let fetchResult else { return [] }

        switch fetchResult {
        case let .success(models):
            return models as? [Model] ?? []
        case let .failure(error):
            throw error
        }
    }
    
    public func add<Model: SendablePersistentModel>(_ models: [Model]) throws {}
    
    public func delete<Model: SendablePersistentModel>(_ models: [Model]) throws {}
}
