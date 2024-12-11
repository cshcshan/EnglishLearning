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
    typealias EpisodesStore = Store<ViewState, ViewAction>

    @State private(set) var store: EpisodesStore
    
    public var body: some View {
        NavigationStack {
            List(store.state.episodes) { episode in
                ZStack {
                    // Because `NavigationLink` adds `>` symbol for each item, so using put `EpisodeView`
                    // overlay the `NavigationLink` instead put `EpisodeView` inside `NavigationLink`
                    // directly
                    NavigationLink(value: episode) { EmptyView() }.opacity(0)
                    EpisodeView(episode: episode)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .task {
                await store.send(.fetchData(isForce: false))
            }
            .listStyle(.plain)
            // Add the smallest positive integer to avoid the content in the scrollView overlay with
            // status bar when scrolling up
            .padding(.top, 1)
            .navigationDestination(for: Episode.self) { episode in
                EpisodeDetailView(episode: episode)
            }
        }
    }
    
    public init(htmlConvertable: HtmlConvertable, episodeDataSource: DataSource<Episode>?) {
        let reducer = ViewReducer()
        let serverNewEpisodesChecker = ServerEpisodesChecker(episodesDataSource: episodeDataSource)
        let fetchEpisodeMiddleware = FetchEpisodeMiddleware(
            htmlConvertable: htmlConvertable,
            episodeDataSource: episodeDataSource,
            hasServerNewEpisodes: serverNewEpisodesChecker.hasServerNewEpisodes(with: Date())
        )
        self.store = EpisodesStore(
            initialState: ViewState(),
            reducer: reducer.process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
    }
}

extension EpisodesView {
    struct ViewState {
        let isFetchingData: Bool
        let episodes: [Episode]
        let fetchDataError: Error?
        
        init(isFetchingData: Bool = false, episodes: [Episode] = [], fetchDataError: Error? = nil) {
            self.isFetchingData = isFetchingData
            self.episodes = episodes
            self.fetchDataError = fetchDataError
        }
    }
    
    enum ViewAction {
        case fetchData(isForce: Bool)
        case setIsLoading
        case fetchedData(Result<[Episode], Error>)
    }
    
    struct ViewReducer {
        let process: EpisodesStore.Reducer = { state, action in
            switch action {
            case let .fetchData(isForce):
                return state
            case .setIsLoading:
                return ViewState(
                    isFetchingData: true, episodes: state.episodes, fetchDataError: state.fetchDataError
                )
            case let .fetchedData(result):
                switch result {
                case let .success(episodes):
                    return ViewState(
                        isFetchingData: false, episodes: episodes, fetchDataError: nil
                    )
                case let .failure(error):
                    return ViewState(
                        isFetchingData: false, episodes: state.episodes, fetchDataError: error
                    )
                }
            }
        }
    }
    
    @MainActor
    final class FetchEpisodeMiddleware {
        typealias EpisodeDataSource = any DataProvideable<Episode>
        
        lazy var process: EpisodesStore.Middleware = { state, action in
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
        
        private let fetchEpisodesDescriptor = FetchDescriptor<Episode>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

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
        
        private func fetchDataFromDB(withIsFetching isFetching: Bool) -> AsyncStream<ViewAction> {
            do {
                guard let episodeDataSource else {
                    return fetchDataFromServer(withIsFetching: isFetching)
                }
                if hasServerNewEpisodes {
                    return fetchDataFromServer(withIsFetching: isFetching)
                } else {
                    let episodes = try episodeDataSource.fetch(fetchEpisodesDescriptor)
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
        
        private func fetchDataFromServer(withIsFetching isFetching: Bool) -> AsyncStream<ViewAction> {
            guard !isFetching else {
                return AsyncStream { $0.finish() }
            }
            
            return AsyncStream { continuation in
                Task {
                    continuation.yield(.setIsLoading)

                    do {
                        let htmlEpisodes = try await htmlConvertable.loadEpisodes()
                        try episodeDataSource?.add(htmlEpisodes)
                        let episodes = try episodeDataSource?.fetch(fetchEpisodesDescriptor)
                        
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
