//
//  EpisodeDetailViewTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/11.
//

import Core
import Foundation
import Testing
@testable import Episodes

@MainActor
struct EpisodeDetailViewTests {
    typealias ViewStore = EpisodeDetailView.EpisodeDetailStore
    typealias ViewState = EpisodeDetailView.ViewState
    typealias ViewReducer = EpisodeDetailView.ViewReducer

    @Test func initImageURL() async throws {
        let episode = Episode(
            id: "Episode 241205",
            title: "Can you trust ancestry DNA kits?",
            desc: "Are DNA ancestry tests a reliable way to trace your ancestry?",
            date: Date(),
            imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
            urlString: "/learningenglish/english/features/6-minute-english_2024/ep-241205"
        )
        let episodeDetail = EpisodeDetail(
            id: "Episode 241205",
            scriptHtml: "<p>Hello Swift</p>"
        )
        let mockHtmlConverter = MockHtmlConverter(loadEpisodeDetailResult: .success(episodeDetail))
        let mockDataSource = try DataSource<EpisodeDetail>(
            for: EpisodeDetail.self,
            isStoredInMemoryOnly: true
        )

        let sut = EpisodeDetailView(
            htmlConvertable: mockHtmlConverter,
            episodeDetailDataSource: mockDataSource,
            episode: episode
        )
        #expect(sut.store.state.title == "Can you trust ancestry DNA kits?")
        #expect(
            sut.store.state.imageURL?.absoluteString == "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg"
        )
        #expect(sut.store.state.scriptAttributedString == nil)
        #expect(sut.store.state.fetchDataError == nil)
    }
    
    @Test(arguments: [false, true])
    func fetchData(hasLocalDetail: Bool) async throws {
        let imageURL = URL(string: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg")

        let episodeDetail = EpisodeDetail(
            id: "Episode 241205",
            scriptHtml: "Hello Swift"
        )
        let mockHtmlConverter = MockHtmlConverter(loadEpisodeDetailResult: .success(episodeDetail))
        let mockDataSource = try DataSource<EpisodeDetail>(
            for: EpisodeDetail.self,
            isStoredInMemoryOnly: true
        )
        if hasLocalDetail {
            try mockDataSource.add([episodeDetail])
        }

        let fetchDetailMiddleware = EpisodeDetailView.FetchDetailMiddleware(
            htmlConvertable: mockHtmlConverter,
            episodeDetailDataSource: mockDataSource,
            episodeID: "Episode 241205",
            episodePath: "/learningenglish/english/features/6-minute-english_2024/ep-241205"
        )

        let sut = ViewStore(
            initialState: ViewState(title: "Can you trust ancestry DNA kits?", imageURL: imageURL),
            reducer: ViewReducer().process,
            middlewares: [fetchDetailMiddleware.process]
        )
        await sut.send(.fetchData)
        
        let expectedLoadEpisodeDetailCount = hasLocalDetail ? 0 : 1

        let scriptAttributedString = try #require(sut.state.scriptAttributedString)
        #expect(String(scriptAttributedString.characters) == "Hello Swift")
        #expect(await mockHtmlConverter.loadEpisodeDetailCount == expectedLoadEpisodeDetailCount)
    }

}
