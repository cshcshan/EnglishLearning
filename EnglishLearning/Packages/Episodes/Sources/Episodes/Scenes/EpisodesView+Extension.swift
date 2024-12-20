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
        case confirmErrorAlert
    }
    
    @MainActor
    final class ViewReducer {
        lazy var process: EpisodesStore.Reducer = { [weak self] state, action in
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    
                    guard let self else {
                        continuation.yield(.build(with: state, fetchDataError: ViewError.selfIsNull))
                        return
                    }
                    
                    let newState: ViewState
                    
                    switch action {
                    case .fetchData where state.isFetchingData:
                        newState = state
                    case let .fetchData(isForce):
                        do {
                            let serverFetching: () -> Void = {
                                continuation.yield(.build(with: state, isFetchingData: true))
                            }
                            
                            let episodes = isForce
                                ? try await self.fetchDataFromServer(serverFetching: serverFetching)
                                : try await self.fetchDataFromDB(serverFetching: serverFetching)
                            
                            newState = ViewState(
                                isFetchingData: false, allEpisodes: episodes, fetchDataError: nil
                            )
                        } catch {
                            newState = ViewState(
                                isFetchingData: false,
                                allEpisodes: state.allEpisodes,
                                fetchDataError: error
                            )
                        }
                    case .confirmErrorAlert:
                        newState = ViewState.build(with: state, fetchDataError: nil)
                    }
                    
                    continuation.yield(newState)
                }
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
