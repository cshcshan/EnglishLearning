//
//  EpisodesViewTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/29.
//

import Core
import Foundation
import Testing
@testable import Episodes

@MainActor
struct EpisodesViewTests {
    typealias EpisodesStore = EpisodesView.EpisodesStore
    typealias EpisodesState = EpisodesView.EpisodesState
    typealias EpisodesReducer = EpisodesView.EpisodesReducer

    @MainActor
    @Test func fetchData_withIsNotFetching_andForceFetch_andLocalEpisodesIsEmpty_shouldFetchFromServer() async throws {
        let isFetching = false
        let isForceFetch = true
        let localEpisodes = [Episode]()
        let serverEpisodes = [Episode].dummy(withAmount: 20)

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource
        )
        
        let sut = EpisodesStore(
            initialState: EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        let expectedStates = [
            EpisodesState(),
            EpisodesState(isFetchingData: true),
            EpisodesState(episodes: serverEpisodes)
        ]
        #expect(actualStates == expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == 1)
    }

    @MainActor
    @Test func fetchData_withIsNotFetching_andForceFetch_andLocalEpisodesIsNotEmpty_shouldFetchFromServer() async throws {
        let isFetching = false
        let isForceFetch = true
        let localEpisodes = [Episode].dummy(withAmount: 10)
        let serverEpisodes = [Episode].dummy(withAmount: 20)

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource
        )
        
        let sut = EpisodesStore(
            initialState: EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        let expectedStates = [
            EpisodesState(),
            EpisodesState(isFetchingData: true),
            EpisodesState(episodes: serverEpisodes)
        ]
        #expect(actualStates == expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == 1)
    }
    
    @Test func fetchData_withIsNotFetching_andNotForceFetch_andLocalEpisodesIsEmpty_shouldFetchFromServer() async throws {
        let isFetching = false
        let isForceFetch = false
        let localEpisodes = [Episode]()
        let serverEpisodes = [Episode].dummy(withAmount: 20)

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource
        )
        
        let sut = EpisodesStore(
            initialState: EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        let expectedStates = [
            EpisodesState(),
            EpisodesState(isFetchingData: true),
            EpisodesState(episodes: serverEpisodes)
        ]
        #expect(actualStates == expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == 1)
    }
    
    @Test func fetchData_withIsNotFetching_andNotForceFetch_andLocalEpisodesIsNotEmpty_shouldFetchFromDB() async throws {
        let isFetching = false
        let isForceFetch = false
        let localEpisodes = [Episode].dummy(withAmount: 10)
        let serverEpisodes = [Episode].dummy(withAmount: 20)

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource
        )
        
        let sut = EpisodesStore(
            initialState: EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        let expectedStates = [
            EpisodesState(),
            EpisodesState(episodes: localEpisodes)
        ]
        #expect(actualStates == expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == 0)
    }

    @Test func fetchData_withIsFetching_andForceFetch_shouldNotFetchFromServerAgain() async throws {
        let isFetching = true
        let isForceFetch = true
        let localEpisodes = [Episode]()
        let serverEpisodes = [Episode].dummy(withAmount: 20)
        
        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource<Episode>.mock(with: localEpisodes)
        let fetchEpisodeMiddleware = EpisodesView.FetchEpisodeMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDataSource: mockDataSource
        )
        
        let sut = EpisodesStore(
            initialState: EpisodesState(isFetchingData: isFetching),
            reducer: EpisodesReducer().process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
        
        var actualStates: [EpisodesState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        let expectedStates = [
            EpisodesState(isFetchingData: true)
        ]
        #expect(actualStates == expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == 0)
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
