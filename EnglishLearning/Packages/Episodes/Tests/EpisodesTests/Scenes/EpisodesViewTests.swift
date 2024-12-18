//
//  EpisodesViewTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/29.
//

import Core
import Foundation
import SwiftData
import Testing
@testable import Episodes

@MainActor
struct EpisodesViewTests {
    typealias ViewStore = EpisodesView.EpisodesStore
    typealias ViewState = EpisodesView.ViewState
    typealias ViewReducer = EpisodesView.ViewReducer
    
    struct Arguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let hasServerNewEpisodes: Bool
        let expectedStates: [ViewState]
        let expectedLoadEpisodesCount: Int
    }

    struct ErrorArguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let expectedStates: [ViewState]
        let expectedLoadLocalEpisodesCount: Int
        let expectedLoadServerEpisodesCount: Int
    }

    struct ConfirmErrorArguments {
        let isFetching: Bool
        let hasEpisodes: Bool
    }
    
    @Test(
        arguments: [
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [
                    ViewState(),
                    ViewState(isFetchingData: true),
                    ViewState(episodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: true,
                expectedStates: [
                    ViewState(),
                    ViewState(isFetchingData: true),
                    ViewState(episodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: false,
                expectedStates: [
                    ViewState(),
                    ViewState(episodes: .localEpisodes)
                ],
                expectedLoadEpisodesCount: 0
            ),
            Arguments(
                isFetching: true,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [ViewState(isFetchingData: true)],
                expectedLoadEpisodesCount: 0
            ),
            // Others
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: false,
                expectedStates: [
                    ViewState(),
                    ViewState(isFetchingData: true),
                    ViewState(episodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            )
        ]
    )
    func fetchData(arguments: Arguments) async throws {
        let isFetching = arguments.isFetching
        let isForceFetch = arguments.isForceFetch
        let localEpisodes: [Episode] = .localEpisodes
        let serverEpisodes: [Episode] = .serverEpisodes
        let hasServerNewEpisodes = arguments.hasServerNewEpisodes

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            hasServerNewEpisodes: hasServerNewEpisodes
        )
        
        let sut = ViewStore(
            initialState: ViewState(isFetchingData: isFetching),
            reducer: ViewReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [ViewState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        #expect(actualStates == arguments.expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == arguments.expectedLoadEpisodesCount)
    }
    
    @Test(
        arguments: [
            ErrorArguments(
                isFetching: false,
                isForceFetch: true,
                expectedStates: [
                    ViewState(),
                    ViewState(isFetchingData: true),
                    ViewState(fetchDataError: DummyError.fetchServerDataError)
                ],
                expectedLoadLocalEpisodesCount: 0,
                expectedLoadServerEpisodesCount: 1
            ),
            ErrorArguments(
                isFetching: false,
                isForceFetch: false,
                expectedStates: [
                    ViewState(),
                    ViewState(fetchDataError: DummyError.fetchLocalDataError)
                ],
                expectedLoadLocalEpisodesCount: 1,
                expectedLoadServerEpisodesCount: 0
            )
        ]
    )
    func fetchData_withError(arguments: ErrorArguments) async throws {
        let isFetching = arguments.isFetching
        let isForceFetch = arguments.isForceFetch

        let mockHtmlConverter = MockHtmlConverter(loadEpisodesResult: .failure(.fetchServerDataError))
        let mockDataSource = MockDataSource(fetchResult: .failure(.fetchLocalDataError))
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            hasServerNewEpisodes: false
        )
        
        let sut = ViewStore(
            initialState: ViewState(isFetchingData: isFetching),
            reducer: ViewReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [ViewState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        await sut.send(.fetchData(isForce: isForceFetch))
        
        #expect(actualStates == arguments.expectedStates)
        #expect(mockDataSource.fetchCount == arguments.expectedLoadLocalEpisodesCount)
        #expect(await mockHtmlConverter.loadEpisodesCount == arguments.expectedLoadServerEpisodesCount)
    }
    
    @Test(
        arguments: [
            ConfirmErrorArguments(isFetching: false, hasEpisodes: false),
            ConfirmErrorArguments(isFetching: false, hasEpisodes: true),
            ConfirmErrorArguments(isFetching: true, hasEpisodes: false),
            ConfirmErrorArguments(isFetching: true, hasEpisodes: true)
        ]
    )
    func confirmErrorAlert(arguments: ConfirmErrorArguments) async throws {
        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = MockDataSource()
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            hasServerNewEpisodes: false
        )

        let episodes: [Episode] = arguments.hasEpisodes ? .dummy(withAmount: 10) : []
        
        let sut = ViewStore(
            initialState: ViewState(
                isFetchingData: arguments.isFetching,
                episodes: episodes,
                fetchDataError: DummyError.fetchServerDataError
            ),
            reducer: ViewReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        let dummyError = try #require(sut.state.fetchDataError as? DummyError)
        #expect(dummyError == .fetchServerDataError)
        #expect(sut.state.isFetchingData == arguments.isFetching)
        #expect(sut.state.episodes == episodes)
        
        await sut.send(.confirmErrorAlert)
        
        #expect(sut.state.fetchDataError == nil)
        #expect(sut.state.isFetchingData == arguments.isFetching)
        #expect(sut.state.episodes == episodes)
    }
}

extension EpisodesViewTests {
    private func startObserving(_ store: ViewStore, onChange: @escaping @Sendable () -> Void) {
        withObservationTracking {
            _ = store.state
        } onChange: {
            onChange()
            Task {
                // We should observe again, otherwise, we can't receive changed event after `onChange()`
                // triggered
                await startObserving(store, onChange: onChange)
            }
        }
    }
}

extension DataSource {
    @MainActor
    fileprivate static func mock(with episodes: [Episode] = []) throws -> DataSource {
        let mockDataSource = try DataSource(with: .mock(isStoredInMemoryOnly: true))
        if !episodes.isEmpty {
            try mockDataSource.add(episodes)
        }
        return mockDataSource
    }
}

extension [Episode] {
    fileprivate static var localEpisodes: [Episode] {
        [Episode].dummy(withAmount: 10)
    }
    
    fileprivate static var serverEpisodes: [Episode] {
        [Episode].dummy(withAmount: 20)
    }
}
