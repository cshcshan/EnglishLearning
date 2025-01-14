//
//  MockServerEpisodesChecker.swift
//  Episodes
//
//  Created by Han Chen on 2025/1/14.
//

import Foundation

actor MockServerEpisodesChecker: ServerEpisodesCheckable {
    var hasServerNewEpisodesResult: Bool
    private(set) var hasServerNewEpisodesCount = 0
    
    init(hasServerNewEpisodesResult: Bool) {
        self.hasServerNewEpisodesResult = hasServerNewEpisodesResult
    }
    
    func hasServerNewEpisodes(with now: Date) async -> Bool {
        hasServerNewEpisodesCount += 1
        return hasServerNewEpisodesResult
    }
}
