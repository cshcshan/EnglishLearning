//
//  ServerNewEpisodesChecker.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/3.
//

import Core
import Foundation
import SwiftData

struct ServerEpisodesChecker {
    private let episodesDataSource: DataSource<Episode>?
    
    init(episodesDataSource: DataSource<Episode>?) {
        self.episodesDataSource = episodesDataSource
    }
    
    func hasServerNewEpisodes(with now: Date) -> Bool {
        var fetchDescriptor = FetchDescriptor<Episode>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        fetchDescriptor.fetchLimit = 1
        
        guard let lastLocalEpisodeDate = try? episodesDataSource?.fetch(fetchDescriptor).last?.date,
              let lastThursday = now.lastWeekday(.thursday)
        else { return true }

        let compareResult = lastLocalEpisodeDate.compare(with: lastThursday, toGranularity: .day)
        switch compareResult {
        case .orderedAscending:
            return true
        case .orderedSame, .orderedDescending:
            return false
        }
    }
}
