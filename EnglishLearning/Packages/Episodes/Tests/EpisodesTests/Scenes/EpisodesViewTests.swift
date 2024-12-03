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
    typealias EpisodesStore = EpisodesView.EpisodesStore
    typealias EpisodesState = EpisodesView.EpisodesState
    typealias EpisodesReducer = EpisodesView.EpisodesReducer
    
    struct Arguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let hasServerNewEpisodes: Bool
        let expectedStates: [EpisodesState]
        let expectedLoadEpisodesCount: Int
    }

    struct ErrorArguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let expectedStates: [EpisodesState]
        let expectedLoadLocalEpisodesCount: Int
        let expectedLoadServerEpisodesCount: Int
    }
    
    @Test(
        arguments: [
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [
                    EpisodesState(),
                    EpisodesState(isFetchingData: true),
                    EpisodesState(episodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: true,
                expectedStates: [
                    EpisodesState(),
                    EpisodesState(isFetchingData: true),
                    EpisodesState(episodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: false,
                expectedStates: [
                    EpisodesState(),
                    EpisodesState(episodes: .localEpisodes)
                ],
                expectedLoadEpisodesCount: 0
            ),
            Arguments(
                isFetching: true,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [EpisodesState(isFetchingData: true)],
                expectedLoadEpisodesCount: 0
            ),
            // Others
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: false,
                expectedStates: [
                    EpisodesState(),
                    EpisodesState(isFetchingData: true),
                    EpisodesState(episodes: .serverEpisodes)
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
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource,
            hasServerNewEpisodes: hasServerNewEpisodes
        )
        
        let sut = EpisodesView.EpisodesStore(
            initialState: EpisodesView.EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesView.EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesView.EpisodesState] = []
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
                    EpisodesState(),
                    EpisodesState(isFetchingData: true),
                    EpisodesState(fetchDataError: DummyError.fetchServerDataError)
                ],
                expectedLoadLocalEpisodesCount: 0,
                expectedLoadServerEpisodesCount: 1
            ),
            ErrorArguments(
                isFetching: false,
                isForceFetch: false,
                expectedStates: [
                    EpisodesState(),
                    EpisodesState(fetchDataError: DummyError.fetchLocalDataError)
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
        let mockDataSource = MockDataSource<Episode>(fetchResult: .failure(.fetchLocalDataError))
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource,
            hasServerNewEpisodes: false
        )
        
        let sut = EpisodesView.EpisodesStore(
            initialState: EpisodesView.EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesView.EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesView.EpisodesState] = []
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
}

extension EpisodesViewTests {
    private func startObserving(_ store: EpisodesStore, onChange: @escaping @Sendable () -> Void) {
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

extension DataSource<Episode> {
    @MainActor
    fileprivate static func mock(with episodes: [Episode] = []) throws -> Self {
        let mockDataSource = try DataSource<Episode>(for: Episode.self, isStoredInMemoryOnly: true)
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
