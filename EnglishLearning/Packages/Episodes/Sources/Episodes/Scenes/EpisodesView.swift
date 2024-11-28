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
    typealias EpisodesStore = Store<EpisodeState, EpisodeAction>

    @State private var store: EpisodesStore
    // NOTE:
    // We need keep `EpisodeReducer` as global variable, otherwise, `self` in `EpisodeReducer.reducer`
    // will be **null**
    private let reducer: EpisodeReducer
    
    public var body: some View {
        VStack {
            Text("Hello, World!")
            Text("isFetchingData: \(store.state.isFetchingData)")
            Text("Episodes count: \(store.state.episodes.count)")
        }
        .onAppear {
            Task { [store] in
                await store.send(.fetchData(isForce: true))
            }
        }
    }
    
    public init(htmlConverter: HtmlConverter, episodeDataSource: DataSource<Episode>?) {
        self.reducer = EpisodeReducer(
            htmlConverter: htmlConverter,
            episodeDataSource: episodeDataSource
        )
        self.store = EpisodesStore(initialState: EpisodeState(), reducer: reducer.reducer)
    }
}

extension EpisodesView {
    struct EpisodeState {
        let isFetchingData: Bool
        let episodes: [Episode]
        let fetchDataError: Error?
        
        init(isFetchingData: Bool = false, episodes: [Episode] = [], fetchDataError: Error? = nil) {
            self.isFetchingData = isFetchingData
            self.episodes = episodes
            self.fetchDataError = fetchDataError
        }
    }
    
    enum EpisodeAction {
        case fetchData(isForce: Bool)
    }
    
    @MainActor
    public final class EpisodeReducer {
        let htmlConverter: HtmlConverter
        let episodeDataSource: DataSource<Episode>?
        
        lazy var reducer: @MainActor (inout EpisodeState, EpisodeAction) async -> Void = { [weak self] state, action in
            switch action {
            case let .fetchData(isForce):
                if isForce {
                    await self?.fetchDataFromServer(state: &state)
                } else {
                    await self?.fetchDataFromDB(state: &state)
                }
            }
        }
        
        // MARK: - Initializers
        
        public init(htmlConverter: HtmlConverter, episodeDataSource: DataSource<Episode>?) {
            self.htmlConverter = htmlConverter
            self.episodeDataSource = episodeDataSource
        }
        
        private func fetchDataFromDB(state: inout EpisodeState) async {
            do {
                let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())
                // TODO: call `fetchDataFromServer()` when the latest episode has released but app
                // doesn't download it
                if episodes == nil || episodes?.isEmpty == true {
                    await fetchDataFromServer(state: &state)
                } else {
                    state = EpisodeState(episodes: episodes ?? [])
                }
            } catch {
                state = EpisodeState(episodes: state.episodes, fetchDataError: error)
            }
        }
        
        private func fetchDataFromServer(state: inout EpisodeState) async {
            state = EpisodeState(isFetchingData: true)
            
            do {
                let htmlEpisodes = try await htmlConverter.loadEpisodes()
                try episodeDataSource?.add(htmlEpisodes)
                let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())
                
                state = EpisodeState(episodes: episodes ?? htmlEpisodes)
            } catch {
                state = EpisodeState(episodes: state.episodes, fetchDataError: error)
            }
        }
    }
}

#Preview {
    let episodeDataSource = try! DataSource<Episode>(for: Episode.self, isStoredInMemoryOnly: true)
    EpisodesView(htmlConverter: .init(), episodeDataSource: episodeDataSource)
}
