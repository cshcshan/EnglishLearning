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
    typealias EpisodesStore = Store<EpisodesState, EpisodesAction>

    @State private(set) var store: EpisodesStore
    
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
    
    public init(htmlConvertable: HtmlConvertable, episodeDataSource: DataSource<Episode>?) {
        let reducer = EpisodesReducer()
        let fetchEpisodeMiddleware = FetchEpisodeMiddleware(
            htmlConvertable: htmlConvertable,
            episodeDataSource: episodeDataSource
        )
        self.store = EpisodesStore(
            initialState: EpisodesState(),
            reducer: reducer.process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
    }
}

extension EpisodesView {
    struct EpisodesState {
        let isFetchingData: Bool
        let episodes: [Episode]
        let fetchDataError: Error?
        
        init(isFetchingData: Bool = false, episodes: [Episode] = [], fetchDataError: Error? = nil) {
            self.isFetchingData = isFetchingData
            self.episodes = episodes
            self.fetchDataError = fetchDataError
        }
    }
    
    enum EpisodesAction {
        case fetchData(isForce: Bool)
        case setIsLoading
        case fetchedData(Result<[Episode], Error>)
    }
    
    struct EpisodesReducer {
        let process: Store<EpisodesState, EpisodesAction>.Reducer = { state, action in
            switch action {
            case let .fetchData(isForce):
                return state
            case .setIsLoading:
                return EpisodesState(isFetchingData: true, episodes: state.episodes)
            case let .fetchedData(result):
                switch result {
                case let .success(episodes):
                    return EpisodesState(episodes: episodes)
                case let .failure(error):
                    return EpisodesState(episodes: state.episodes, fetchDataError: error)
                }
            }
        }
    }
    
    @MainActor
    final class FetchEpisodeMiddleware {
        lazy var process: Store<EpisodesState, EpisodesAction>.Middleware = { state, action in
            switch action {
            case let .fetchData(isForce):
                return isForce ? self.fetchDataFromServer() : self.fetchDataFromDB()
            case .setIsLoading, .fetchedData:
                return AsyncStream { $0.finish() }
            }
        }
        
        private let htmlConvertable: HtmlConvertable
        private let episodeDataSource: DataSource<Episode>?
        
        init(htmlConvertable: HtmlConvertable, episodeDataSource: DataSource<Episode>?) {
            self.htmlConvertable = htmlConvertable
            self.episodeDataSource = episodeDataSource
        }
        
        private func fetchDataFromDB() -> AsyncStream<EpisodesAction> {
            do {
                let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())
                // TODO: call `fetchDataFromServer()` when the latest episode has released but app
                // doesn't download it
                if episodes == nil || episodes?.isEmpty == true {
                    return fetchDataFromServer()
                } else {
                    return AsyncStream {
                        $0.yield(.fetchedData(.success(episodes ?? [])))
                        $0.finish()
                    }
                }
            } catch {
                return AsyncStream {
                    $0.yield(.fetchedData(.failure(error)))
                    $0.finish()
                }
            }
        }
        
        private func fetchDataFromServer() -> AsyncStream<EpisodesAction> {
            AsyncStream { continuation in
                Task {
                    continuation.yield(.setIsLoading)

                    do {
                        let htmlEpisodes = try await htmlConvertable.loadEpisodes()
                        try episodeDataSource?.add(htmlEpisodes)
                        let episodes = try episodeDataSource?.fetch(FetchDescriptor<Episode>())
                        
                        continuation.yield(.fetchedData(.success(episodes ?? htmlEpisodes)))
                    } catch {
                        continuation.yield(.fetchedData(.failure(error)))
                    }

                    continuation.finish()
                }
            }
        }
    }
}

#Preview {
    let episodeDataSource = try! DataSource<Episode>(for: Episode.self, isStoredInMemoryOnly: true)
    EpisodesView(htmlConvertable: HtmlConverter(), episodeDataSource: episodeDataSource)
}
