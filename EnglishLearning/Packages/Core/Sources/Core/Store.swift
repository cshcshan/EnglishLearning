//
//  Store.swift
//  Core
//
//  Created by Han Chen on 2024/11/27.
//

import Foundation
import Observation

/// Inspired by https://github.com/mecid/swift-unidirectional-flow
@MainActor
@Observable
public final class Store<State: Sendable, Action: Sendable> {
    public typealias Reducer = @MainActor (State, Action) -> State
    public typealias Middleware = @MainActor (State, Action) async -> Action?

    public private(set) var state: State
    private let reducer: Reducer
    private let middlewares: [Middleware]

    public init(
        initialState state: State,
        reducer: @escaping Reducer,
        middlewares: [Middleware] = []
    ) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    public func send(_ action: Action) async {
        reduce(with: action)
        await reduceMiddlewares(with: action)
    }
    
    private func reduce(with action: Action) {
        state = reducer(state, action)
    }
    
    private func reduceMiddlewares(with action: Action) async {
        await withTaskGroup(of: Action?.self) { group in
            for middleware in middlewares {
                group.addTask {
                    return await middleware(self.state, action)
                }
            }
            
            for await case let nextAction? in group {
                await send(nextAction)
            }
        }
    }
}
