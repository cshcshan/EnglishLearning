//
//  EpisodesView+Extension.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/19.
//

import Core
import Foundation
import SwiftData

extension EpisodesView {
    struct ViewState {
        let isFetchingData: Bool
        let allEpisodes: [Episode]
        let fetchDataError: Error?

        static var `default`: ViewState {
            ViewState(
                isFetchingData: false,
                allEpisodes: [],
                fetchDataError: nil
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil
        ) -> ViewState {
            build(
                with: state,
                isFetchingData: isFetchingData,
                allEpisodes: allEpisodes,
                fetchDataError: state.fetchDataError
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil,
            fetchDataError: Error?
        ) -> ViewState {
            ViewState(
                isFetchingData: isFetchingData ?? state.isFetchingData,
                allEpisodes: allEpisodes ?? state.allEpisodes,
                fetchDataError: fetchDataError
            )
        }
    }
    
    enum ViewAction {
        case fetchData(isForce: Bool)
        case setIsLoading
        case fetchedData(Result<[Episode], Error>)
        case confirmErrorAlert
    }
    
    struct ViewReducer {
        let process: EpisodesStore.Reducer = { state, action in
            switch action {
            case let .fetchData(isForce):
                return state
            case .setIsLoading:
                return .build(with: state, isFetchingData: true)
            case let .fetchedData(result):
                switch result {
                case let .success(episodes):
                    return ViewState(
                        isFetchingData: false, allEpisodes: episodes, fetchDataError: nil
                    )
                case let .failure(error):
                    return ViewState(
                        isFetchingData: false, allEpisodes: state.allEpisodes, fetchDataError: error
                    )
                }
            case .confirmErrorAlert:
                return .build(with: state, fetchDataError: nil)
            }
        }
    }
    
    @MainActor
    final class FetchEpisodeMiddleware {
        lazy var process: EpisodesStore.Middleware = { [weak self] state, action in
            switch action {
            case let .fetchData(isForce):
                guard let self else {
                    return AsyncStream {
                        $0.yield(.fetchedData(.failure(ViewError.selfIsNull)))
                        $0.finish()
                    }
                }

                let isFetching = state.isFetchingData
                return isForce
                    ? self.fetchDataFromServer(withIsFetching: isFetching)
                    : self.fetchDataFromDB(withIsFetching: isFetching)
            case .setIsLoading, .fetchedData, .confirmErrorAlert:
                return AsyncStream { $0.finish() }
            }
        }
        
        private let fetchEpisodesDescriptor = FetchDescriptor<Episode>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        private let htmlConvertable: HtmlConvertable
        private let dataProvideable: any DataProvideable
        private let hasServerNewEpisodes: Bool
        
        init(
            htmlConvertable: HtmlConvertable,
            dataProvideable: any DataProvideable,
            hasServerNewEpisodes: Bool
        ) {
            self.htmlConvertable = htmlConvertable
            self.dataProvideable = dataProvideable
            self.hasServerNewEpisodes = hasServerNewEpisodes
        }
        
        private func fetchDataFromDB(withIsFetching isFetching: Bool) -> AsyncStream<ViewAction> {
            if hasServerNewEpisodes {
                return fetchDataFromServer(withIsFetching: isFetching)
            } else {
                return AsyncStream { continuation in
                    Task {
                        do {
                            let episodes = try dataProvideable.fetch(fetchEpisodesDescriptor)
                            continuation.yield(.fetchedData(.success(episodes)))
                        } catch {
                            await Log.data.add(error: error)
                            continuation.yield(.fetchedData(.failure(error)))
                        }
                        continuation.finish()
                    }
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
                        try dataProvideable.add(htmlEpisodes)
                        let episodes = try dataProvideable.fetch(fetchEpisodesDescriptor)
                        
                        continuation.yield(.fetchedData(.success(episodes)))
                    } catch {
                        await Log.network.add(error: error)
                        continuation.yield(.fetchedData(.failure(error)))
                    }

                    continuation.finish()
                }
            }
        }
    }
    
    enum ViewError: Error {
        case selfIsNull
    }
}

extension EpisodesView.ViewState: CustomStringConvertible {
    var description: String {
        """
        [EpisodesView.ViewState]
        isFetchingData: \(isFetchingData)
        allEpisodes: \(allEpisodes.map(\.description).joined(separator: "\n"))
        fetchDataError: \(fetchDataError.map { $0.localizedDescription } ?? "nil")
        """
    }
}
