//
//  FavoriteEpisodes.swift
//  FavoriteEpisodesWidgetExtension
//
//  Created by Han Chen on 2024/12/26.
//

import Core
import Episodes
import Foundation
import SwiftData

struct FavoriteEpisodes {
    private let userDefaultsManager: UserDefaultsManager
    private let modelContainer: ModelContainer?
    private let dataSource: DataSource?
    
    @MainActor
    init() {
        self.userDefaultsManager = UserDefaultsManager(store: .appGroup ?? .standard)

        do {
            let modelContainer = try ModelContainer.buildProd()
            self.dataSource = try DataSource(with: modelContainer)
            self.modelContainer = modelContainer
        } catch {
            Task { await Log.data.add(error: error) }
            self.modelContainer = nil
            self.dataSource = nil
        }
    }
    
    func callAsFunction() -> [Episode] {
        let favEpisodeIDs = userDefaultsManager.favoriteEpisodeIDs

        guard let dataSource, !favEpisodeIDs.isEmpty else { return [] }
        
        // 1. Since the error "Predicate body may only contain one expression" occurred, we couldn't use
        //    `guard-else` here.
        // 2. Since the error "Unsupported Predicate: The 'Foundation.PredicateExpressions.ForcedUnwrap'
        //    operator is not supported", we couldn't use `episode.id!` directly
        let predicate = #Predicate<Episode>{ episode in
            episode.id.flatMap { id in favEpisodeIDs.contains(id) } ?? false
        }
        let sortBy = SortDescriptor<Episode>(\.date, order: .reverse)

        do {
            return try dataSource.fetch(FetchDescriptor(predicate: predicate, sortBy: [sortBy]))
        } catch {
            Task { await Log.data.add(error: error) }
            return []
        }
    }
}

