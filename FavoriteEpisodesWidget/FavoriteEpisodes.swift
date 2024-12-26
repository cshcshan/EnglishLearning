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
        guard let dataSource else { return [] }
        
        let favEpisodeIDs = userDefaultsManager.favoriteEpisodeIDs
        // Since the error "Predicate body may only contain one expression" occurred, we couldn't use
        // `guard-else` here
        let predicate = #Predicate<Episode>{ episode in
            episode.id != nil && favEpisodeIDs.contains(episode.id!)
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

