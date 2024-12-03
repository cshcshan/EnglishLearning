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
        let serverNewEpisodesChecker = ServerEpisodesChecker(episodesDataSource: episodeDataSource)
        let fetchEpisodeMiddleware = FetchEpisodeMiddleware(
            htmlConvertable: htmlConvertable,
            episodeDataSource: episodeDataSource,
            hasServerNewEpisodes: serverNewEpisodesChecker.hasServerNewEpisodes(with: Date())
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
                return EpisodesState(
                    isFetchingData: true, episodes: state.episodes, fetchDataError: state.fetchDataError
                )
            case let .fetchedData(result):
                switch result {
                case let .success(episodes):
                    return EpisodesState(
                        isFetchingData: false, episodes: episodes, fetchDataError: nil
                    )
                case let .failure(error):
                    return EpisodesState(
                        isFetchingData: false, episodes: state.episodes, fetchDataError: error
                    )
                }
            }
        }
    }
    
    @MainActor
    final class FetchEpisodeMiddleware {
        typealias EpisodeDataSource = any DataProvideable<Episode>
        
        lazy var process: Store<EpisodesState, EpisodesAction>.Middleware = { state, action in
            switch action {
            case let .fetchData(isForce):
                let isFetching = state.isFetchingData
                return isForce
                    ? self.fetchDataFromServer(withIsFetching: isFetching)
                    : self.fetchDataFromDB(withIsFetching: isFetching)
            case .setIsLoading, .fetchedData:
                return AsyncStream { $0.finish() }
            }
        }
        
        private let htmlConvertable: HtmlConvertable
        private let episodeDataSource: EpisodeDataSource?
        private let hasServerNewEpisodes: Bool
        
        init(
            htmlConvertable: HtmlConvertable,
            episodeDataSource: EpisodeDataSource?,
            hasServerNewEpisodes: Bool
        ) {
            self.htmlConvertable = htmlConvertable
            self.episodeDataSource = episodeDataSource
            self.hasServerNewEpisodes = hasServerNewEpisodes
        }
        
        private func fetchDataFromDB(withIsFetching isFetching: Bool) -> AsyncStream<EpisodesAction> {
            do {
                guard let episodeDataSource else {
                    return fetchDataFromServer(withIsFetching: isFetching)
                }
                if hasServerNewEpisodes {
                    return fetchDataFromServer(withIsFetching: isFetching)
                } else {
                    let episodes = try episodeDataSource.fetch(FetchDescriptor<Episode>())
                    return AsyncStream {
                        $0.yield(.fetchedData(.success(episodes)))
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
        
        private func fetchDataFromServer(withIsFetching isFetching: Bool) -> AsyncStream<EpisodesAction> {
            guard !isFetching else {
                return AsyncStream { $0.finish() }
            }
            
            return AsyncStream { continuation in
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
    let episodes = [Episode].dummy(withAmount: 10)
    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodesResult(.success(episodes)) }
    let episodeDataSource = try! DataSource<Episode>(for: Episode.self, isStoredInMemoryOnly: true)
    return EpisodesView(htmlConvertable: HtmlConverter(), episodeDataSource: episodeDataSource)
}
