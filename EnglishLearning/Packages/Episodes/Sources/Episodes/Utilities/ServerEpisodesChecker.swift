//
//  ServerNewEpisodesChecker.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/3.
//

import Core
import Foundation
import SwiftData

protocol ServerEpisodesCheckable: Sendable {
    func hasServerNewEpisodes(with now: Date) async -> Bool
}

struct ServerEpisodesChecker: ServerEpisodesCheckable {
    private let dataSource: DataSource
    
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    func hasServerNewEpisodes(with now: Date) async -> Bool {
        var fetchDescriptor = FetchDescriptor<Episode>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        fetchDescriptor.fetchLimit = 1
        
        guard let lastLocalEpisodeDate = try? await dataSource.fetch(fetchDescriptor).last?.date,
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
