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
    public typealias Reducer = @MainActor (State, Action) -> AsyncStream<ReduceResult>
    
    public enum ReduceResult: Sendable {
        case state(State)
        case action(Action)
    }

    public private(set) var state: State
    private let reducer: Reducer

    public init(
        initialState state: State,
        reducer: @escaping Reducer
    ) {
        self.state = state
        self.reducer = reducer
        
        #if DEBUG
        self.startObservingState()
        #endif
    }

    public func send(_ action: Action) async {
        for await result in reducer(state, action) {
            switch result {
            case let .state(state):
                self.state = state
            case let .action(action):
                await self.send(action)
            }
        }
    }
    
    private func startObservingState() {
        withObservationTracking {
            _ = state
        } onChange: {
            Task { [weak self] in
                guard let self else { return }
                await Log.viewState.add(level: .debug, message: "\(self.state)")
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.startObservingState()
            }
        }

    }
}
