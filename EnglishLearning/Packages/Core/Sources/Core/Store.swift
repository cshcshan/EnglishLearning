//
//  Store.swift
//  Core
//
//  Created by Han Chen on 2024/11/27.
//

import Foundation
import Observation

@Observable
public final class Store<State, Action> {
    public private(set) var state: State
    private let reducer: (inout State, Action) -> Void

    public init(
        initialState state: State,
        reducer: @escaping (inout State, Action) -> Void
    ) {
        self.state = state
        self.reducer = reducer
    }

    public func send(_ action: Action) {
        reducer(&state, action)
    }
}
