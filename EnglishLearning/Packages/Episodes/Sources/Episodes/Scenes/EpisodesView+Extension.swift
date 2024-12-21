//
//  EpisodesView+Extension.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/19.
//

import Core
import Foundation
import SwiftData
import SwiftUI

extension EpisodesView {
    struct ViewState {
        let isFetchingData: Bool
        let allEpisodes: [Episode]
        let favoriteEpisodes: [Episode]
        let fetchDataError: Error?

        static var `default`: ViewState {
            ViewState(
                isFetchingData: false,
                allEpisodes: [],
                favoriteEpisodes: [],
                fetchDataError: nil
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil,
            favoriteEpisodes: [Episode]? = nil
        ) -> ViewState {
            build(
                with: state,
                isFetchingData: isFetchingData,
                allEpisodes: allEpisodes,
                favoriteEpisodes: favoriteEpisodes,
                fetchDataError: state.fetchDataError
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil,
            favoriteEpisodes: [Episode]? = nil,
            fetchDataError: Error?
        ) -> ViewState {
            ViewState(
                isFetchingData: isFetchingData ?? state.isFetchingData,
                allEpisodes: allEpisodes ?? state.allEpisodes,
                favoriteEpisodes: favoriteEpisodes ?? state.favoriteEpisodes,
                fetchDataError: fetchDataError
            )
        }
    }
    
    enum ViewAction {
        case fetchData(isForce: Bool)
        case confirmErrorAlert
        case addFavorite(episodeID: String)
        case removeFavorite(episodeID: String)
    }
    
    @MainActor
    final class ViewReducer {
        lazy var process: EpisodesStore.Reducer = { [weak self] state, action in
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    
                    guard let self else {
                        continuation.yield(
                            .state(.build(with: state, fetchDataError: ViewError.selfIsNull))
                        )
                        return
                    }
                    
                    let newState: ViewState
                    
                    switch action {
                    case .fetchData where state.isFetchingData:
                        newState = state
                    case let .fetchData(isForce):
                        do {
                            let serverFetching: () -> Void = {
                                continuation.yield(.state(.build(with: state, isFetchingData: true)))
                            }
                            
                            let episodes = isForce
                                ? try await self.fetchDataFromServer(serverFetching: serverFetching)
                                : try await self.fetchDataFromDB(serverFetching: serverFetching)
                            
                            newState = ViewState(
                                isFetchingData: false,
                                allEpisodes: episodes,
                                favoriteEpisodes: self.favoriteEpisodes(with: episodes),
                                fetchDataError: nil
                            )
                        } catch {
                            newState = .build(
                                with: state,
                                isFetchingData: false,
                                fetchDataError: error
                            )
                        }
                    case .confirmErrorAlert:
                        newState = .build(with: state, fetchDataError: nil)
                    case let .addFavorite(episodeID):
                        self.userDefaultsManagerable.favoriteEpisodeIDs.insert(episodeID)
                        newState = .build(
                            with: state,
                            favoriteEpisodes: self.favoriteEpisodes(with: state.allEpisodes)
                        )
                    case let .removeFavorite(episodeID):
                        self.userDefaultsManagerable.favoriteEpisodeIDs.remove(episodeID)
                        newState = .build(
                            with: state,
                            favoriteEpisodes: self.favoriteEpisodes(with: state.allEpisodes)
                        )
                    }
                    
                    continuation.yield(.state(newState))
                }
            }
        }
        
        private let fetchEpisodesDescriptor = FetchDescriptor<Episode>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        private let htmlConvertable: HtmlConvertable
        private let dataProvideable: any DataProvideable
        private var userDefaultsManagerable: UserDefaultsManagerable
        private let hasServerNewEpisodes: Bool
        
        init(
            htmlConvertable: HtmlConvertable,
            dataProvideable: any DataProvideable,
            userDefaultsManagerable: UserDefaultsManagerable,
            hasServerNewEpisodes: Bool
        ) {
            self.htmlConvertable = htmlConvertable
            self.dataProvideable = dataProvideable
            self.userDefaultsManagerable = userDefaultsManagerable
            self.hasServerNewEpisodes = hasServerNewEpisodes
        }
        
        private func fetchDataFromDB(serverFetching: () -> Void) async throws -> [Episode] {
            if hasServerNewEpisodes {
                return try await fetchDataFromServer(serverFetching: serverFetching)
            } else {
                do {
                    return try dataProvideable.fetch(fetchEpisodesDescriptor)
                } catch {
                    await Log.data.add(error: error)
                    throw error
                }
            }
        }
        
        private func fetchDataFromServer(serverFetching: () -> Void) async throws -> [Episode] {
            serverFetching()
            
            do {
                let htmlEpisodes = try await htmlConvertable.loadEpisodes()
                try dataProvideable.add(htmlEpisodes)
                return try dataProvideable.fetch(fetchEpisodesDescriptor)
            } catch {
                await Log.network.add(error: error)
                throw error
            }
        }
        
        private func favoriteEpisodes(with allEpisodes: [Episode]) -> [Episode] {
            userDefaultsManagerable.favoriteEpisodeIDs.flatMap { id in
                allEpisodes.filter { $0.id == id }
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
        allEpisodes:
            \(allEpisodes.map { $0.id ?? "null" }.joined(separator: "\n    "))
        favoriteEpisodes: 
            \(favoriteEpisodes.map { $0.id ?? "null" }.joined(separator: "\n    "))
        fetchDataError: \(fetchDataError.map { $0.localizedDescription } ?? "nil")
        """
    }
}
