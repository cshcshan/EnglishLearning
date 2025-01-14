//
//  FavoriteEpisodesProvider.swift
//  FavoriteEpisodesWidgetExtension
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import Foundation
import WidgetKit

struct FavoriteEpisodesProvider: TimelineProvider {
    typealias Entry = FavoriteEpisodesEntry
    
    private let favoriteEpisodes: FavoriteEpisodes
    
    @MainActor
    init() {
        self.favoriteEpisodes = FavoriteEpisodes()
    }
    
    func placeholder(in context: Context) -> FavoriteEpisodesEntry {
        .placeholder
    }
    
    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (FavoriteEpisodesEntry) -> Void
    ) {
        completion(.placeholder)
    }
    
    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<FavoriteEpisodesEntry>) -> Void
    ) {
        Task {
            let episodes = await favoriteEpisodes()
            let entry = FavoriteEpisodesEntry(episodes: episodes)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}
