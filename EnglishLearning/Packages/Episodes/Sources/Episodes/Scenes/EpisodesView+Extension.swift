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
    enum ListType: CaseIterable {
        case all, favorite
        
        var title: String {
            switch self {
            case .all: "All"
            case .favorite: "Favorite"
            }
        }
    }
    
    struct ViewState {
        let isFetchingData: Bool
        let allEpisodes: [Episode]
        let favoriteEpisodes: [Episode]
        let selectedListType: ListType
        let fetchDataError: Error?

        static var `default`: ViewState {
            ViewState(
                isFetchingData: false,
                allEpisodes: [],
                favoriteEpisodes: [],
                selectedListType: .all,
                fetchDataError: nil
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil,
            favoriteEpisodes: [Episode]? = nil,
            selectedListType: ListType? = nil
        ) -> ViewState {
            build(
                with: state,
                isFetchingData: isFetchingData,
                allEpisodes: allEpisodes,
                favoriteEpisodes: favoriteEpisodes,
                selectedListType: selectedListType,
                fetchDataError: state.fetchDataError
            )
        }
        
        static func build(
            with state: ViewState,
            isFetchingData: Bool? = nil,
            allEpisodes: [Episode]? = nil,
            favoriteEpisodes: [Episode]? = nil,
            selectedListType: ListType? = nil,
            fetchDataError: Error?
        ) -> ViewState {
            ViewState(
                isFetchingData: isFetchingData ?? state.isFetchingData,
                allEpisodes: allEpisodes ?? state.allEpisodes,
                favoriteEpisodes: favoriteEpisodes ?? state.favoriteEpisodes,
                selectedListType: selectedListType ?? state.selectedListType,
                fetchDataError: fetchDataError
            )
        }
    }
    
    enum ViewAction {
        case listTypeTapped(ListType)
        case fetchData(isForce: Bool)
        case confirmErrorAlert
        case addFavorite(episodeID: String)
        case removeFavorite(episodeID: String)
    }
    
    @MainActor
    final class ViewReducer {
        struct OrganizedEpisodes {
            let all: [Episode]
            let favorite: [Episode]
        }
        
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
                    case let .listTypeTapped(listType):
                        newState = .build(with: state, selectedListType: listType)
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
                            
                            let organizedEpisodes = self.organizeEpisodes(allEpisodes: episodes)
                            
                            newState = ViewState(
                                isFetchingData: false,
                                allEpisodes: organizedEpisodes.all,
                                favoriteEpisodes: organizedEpisodes.favorite,
                                selectedListType: state.selectedListType,
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
                        let organizedEpisodes = self.organizeEpisodes(allEpisodes: state.allEpisodes)
                        newState = .build(
                            with: state,
                            allEpisodes: organizedEpisodes.all,
                            favoriteEpisodes: organizedEpisodes.favorite
                        )
                    case let .removeFavorite(episodeID):
                        self.userDefaultsManagerable.favoriteEpisodeIDs.remove(episodeID)
                        let organizedEpisodes = self.organizeEpisodes(allEpisodes: state.allEpisodes)
                        newState = .build(
                            with: state,
                            allEpisodes: organizedEpisodes.all,
                            favoriteEpisodes: organizedEpisodes.favorite
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
        
        private func organizeEpisodes(allEpisodes: [Episode]) -> OrganizedEpisodes {
            let favoriteEpisodeIDs = userDefaultsManagerable.favoriteEpisodeIDs
            var newAllEpisodes: [Episode] = []
            var newFavoriteEpisodes: [Episode] = []
            
            allEpisodes.forEach { episode in
                let newEpisode = episode
                if let id = episode.id {
                    newEpisode.isFavorite = favoriteEpisodeIDs.contains(id)
                } else {
                    newEpisode.isFavorite = false
                }
                newAllEpisodes.append(newEpisode)
                
                if newEpisode.isFavorite {
                    newFavoriteEpisodes.append(newEpisode)
                }
            }
            
            return OrganizedEpisodes(all: newAllEpisodes, favorite: newFavoriteEpisodes)
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
