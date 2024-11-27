//
//  EpisodesView.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/27.
//

import Core
import SwiftData
import SwiftUI

public struct EpisodesView: View {
    @State private var viewModel: ViewModel

    public var body: some View {
        VStack {
            Text("Hello, World!")
            Text("Episodes count: \(viewModel.store.state.episodes.count)")
            
        }
        .onAppear {
            viewModel.store.send(.fetchData(isForce: false))
        }
    }
    
    public init(viewModel: EpisodesView.ViewModel) {
        self.viewModel = viewModel
    }
}

extension EpisodesView {
    // Add `@MainActor` for a error caused by `Task` in `reducer()`
    // Error: Passing closure as a 'sending' parameter risks causing data races between code in the
    // current task and concurrent execution of the closure
    @MainActor
    public struct ViewModel {
        typealias EpisodesStore = Store<State, Action>
        
        lazy var store: EpisodesStore = EpisodesStore(
            initialState: State(),
            reducer: reducer
        )
        
        struct State {
            let isFetchingData: Bool
            let episodes: [Episode]
            let fetchDataError: Error?

            init(isFetchingData: Bool = false, episodes: [Episode] = [], fetchDataError: Error? = nil) {
                self.isFetchingData = isFetchingData
                self.episodes = episodes
                self.fetchDataError = fetchDataError
            }
        }
        
        enum Action {
            case fetchData(isForce: Bool)
        }
        
        let htmlConverter: HtmlConverter
        let episodeDataSource: DataSource<Episode>?
        
        private lazy var reducer: (inout State, Action) -> Void = { [self] state, action in
            switch action {
            case let .fetchData(isForce):
                if isForce {
                    self.fetchDataFromServer(state: &state)
                } else {
                    self.fetchDataFromDB(state: &state)
                }
            }
        }
        
        // MARK: - Initializers
        
        public init(htmlConverter: HtmlConverter, episodeDataSource: DataSource<Episode>?) {
            self.htmlConverter = htmlConverter
            self.episodeDataSource = episodeDataSource
        }

        private func fetchDataFromDB(state: inout State) {
            do {
                let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())
                if episodes == nil || episodes?.isEmpty == true {
                    fetchDataFromServer(state: &state)
                } else {
                    state = State(episodes: episodes ?? [])
                }
            } catch {
                state = State(episodes: state.episodes, fetchDataError: error)
            }
        }

        private func fetchDataFromServer(state: inout State) {
            // Error:
            // Escaping closure captures 'inout' parameter 'state'
            var state = state

            // Error
            // Non-sendable type '[Episode]' returned by implicitly asynchronous call to
            // actor-isolated function cannot cross actor boundary
            // Fix by `extension Episode: @unchecked Sendable {}`
            // https://forums.developer.apple.com/forums/thread/725596?answerId=749095022#749095022
            Task {
                do {
                    let htmlEpisodes = try await htmlConverter.loadEpisodes()
                    try episodeDataSource?.add(htmlEpisodes)
                    let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())

                    state = State(episodes: episodes ?? htmlEpisodes)
                } catch {
                    state = State(episodes: state.episodes, fetchDataError: error)
                }
            }
        }
    }
}

#Preview {
    let modelContext = try! ModelContext.default(for: Episode.self, isStoredInMemoryOnly: true)
    let episodeDataSource = DataSource<Episode>(modelContext: modelContext)
    EpisodesView(viewModel: .init(htmlConverter: .init(), episodeDataSource: episodeDataSource))
}
