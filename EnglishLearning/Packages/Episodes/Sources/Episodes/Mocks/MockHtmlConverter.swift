//
//  MockHtmlConverter 2.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/29.
//

#if DEBUG

import Core

actor MockHtmlConverter: HtmlConvertable {
    typealias LoadEpisodesResult = Result<[Episode], DummyError>

    var loadEpisodesResult: LoadEpisodesResult?
    private(set) var loadEpisodesCount = 0

    init(loadEpisodesResult: LoadEpisodesResult? = nil) {
        self.loadEpisodesResult = loadEpisodesResult
    }

    func setLoadEpisodesResult(_ loadEpisodesResult: LoadEpisodesResult) {
        self.loadEpisodesResult = loadEpisodesResult
    }

    func loadEpisodes() async throws -> [Episode] {
        loadEpisodesCount += 1
        guard let loadEpisodesResult else { return [] }

        switch loadEpisodesResult {
        case let .success(episodes):
            return episodes
        case let .failure(error):
            throw error
        }
    }
}

#endif
