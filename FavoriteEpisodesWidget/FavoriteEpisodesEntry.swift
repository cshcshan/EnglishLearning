//
//  FavoriteEpisodesEntry.swift
//  FavoriteEpisodesWidgetExtension
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import Foundation
import WidgetKit

struct FavoriteEpisodesEntry: TimelineEntry {
    let date: Date = .now
    let episodes: [Episode]
}
