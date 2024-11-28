//
//  Store.swift
//  Core
//
//  Created by Han Chen on 2024/11/27.
//

import Foundation
import Observation

@MainActor
@Observable
public final class Store<State, Action> {
    public private(set) var state: State
    private let reducer: @MainActor (inout State, Action) async -> Void

    public init(
        initialState state: State,
        reducer: @escaping @MainActor (inout State, Action) async -> Void
    ) {
        self.state = state
        self.reducer = reducer
    }

    public func send(_ action: Action) async {
        var state = state
        await reducer(&state, action)
        self.state = state
    }
}
