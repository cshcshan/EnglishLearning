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
    typealias LoadEpisodeDetailResult = Result<EpisodeDetail, DummyError>

    var loadEpisodesResult: LoadEpisodesResult?
    private(set) var loadEpisodesCount = 0
    
    var loadEpisodeDetailResult: LoadEpisodeDetailResult?
    private(set) var loadEpisodeDetailCount = 0

    init(
        loadEpisodesResult: LoadEpisodesResult? = nil,
        loadEpisodeDetailResult: LoadEpisodeDetailResult? = nil
    ) {
        self.loadEpisodesResult = loadEpisodesResult
        self.loadEpisodeDetailResult = loadEpisodeDetailResult
    }

    func setLoadEpisodesResult(_ loadEpisodesResult: LoadEpisodesResult) {
        self.loadEpisodesResult = loadEpisodesResult
    }

    func setLoadEpisodeDetailResult(_ loadEpisodeDetailResult: LoadEpisodeDetailResult) {
        self.loadEpisodeDetailResult = loadEpisodeDetailResult
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
    
    func loadEpisodeDetail(withID id: String?, path: String?) async throws -> EpisodeDetail? {
        loadEpisodeDetailCount += 1
        guard let loadEpisodeDetailResult else { return nil }

        switch loadEpisodeDetailResult {
        case let .success(episodeDetail):
            return episodeDetail
        case let .failure(error):
            throw error
        }
    }
}

#endif
