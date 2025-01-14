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
            audioLink: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3",
            scriptHtml: "<p>Hello Swift</p>"
        )
        let mockHtmlConverter = MockHtmlConverter(loadEpisodeDetailResult: .success(episodeDetail))
        let mockDataSource = try DataSource(modelContainer: .mock(isStoredInMemoryOnly: true))

        let sut = EpisodeDetailView(
            htmlConvertable: mockHtmlConverter,
            dataSource: mockDataSource,
            episode: episode
        )
        #expect(sut.store.state.title == "Can you trust ancestry DNA kits?")
        #expect(
            sut.store.state.imageURL?.absoluteString == "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg"
        )
        #expect(sut.store.state.scriptAttributedString == nil)
        #expect(sut.store.state.audioURL == nil)
        #expect(sut.store.state.fetchDataError == nil)
    }
    
    @Test(arguments: [false, true])
    func fetchData(hasLocalDetail: Bool) async throws {
        let imageURL = URL(string: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg")

        let episodeDetail = EpisodeDetail(
            id: "Episode 241205",
            audioLink: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3",
            scriptHtml: "Hello Swift"
        )
        let mockHtmlConverter = MockHtmlConverter(loadEpisodeDetailResult: .success(episodeDetail))
        let mockDataSource = try DataSource(modelContainer: .mock(isStoredInMemoryOnly: true))
        if hasLocalDetail {
            try await mockDataSource.add([episodeDetail])
        }

        let reducer = EpisodeDetailView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataSource: mockDataSource,
            episodeID: "Episode 241205",
            episodePath: "/learningenglish/english/features/6-minute-english_2024/ep-241205"
        )

        let sut = ViewStore(
            initialState: ViewState(
                title: "Can you trust ancestry DNA kits?",
                imageURL: imageURL,
                scriptAttributedString: nil,
                audioURL: nil,
                fetchDataError: nil
            ),
            reducer: reducer.process
        )
        await sut.send(.fetchData)
        
        let expectedLoadEpisodeDetailCount = hasLocalDetail ? 0 : 1

        let scriptAttributedString = try #require(sut.state.scriptAttributedString)
        #expect(String(scriptAttributedString.characters) == "Hello Swift")
        #expect(
            sut.state.audioURL?.absoluteString == "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
        )
        #expect(await mockHtmlConverter.loadEpisodeDetailCount == expectedLoadEpisodeDetailCount)
    }
    
    func confirmErrorAlert() async throws {
        let imageURL = URL(string: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg")

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource(modelContainer: .mock(isStoredInMemoryOnly: true))

        let reducer = EpisodeDetailView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataSource: mockDataSource,
            episodeID: "Episode 241205",
            episodePath: "/learningenglish/english/features/6-minute-english_2024/ep-241205"
        )

        let sut = ViewStore(
            initialState: ViewState(
                title: "Can you trust ancestry DNA kits?",
                imageURL: imageURL,
                scriptAttributedString: nil,
                audioURL: nil,
                fetchDataError: DummyError.fetchServerDataError
            ),
            reducer: reducer.process
        )
        
        let dummyError = try #require(sut.state.fetchDataError as? DummyError)
        #expect(dummyError == .fetchServerDataError)
        #expect(sut.state.title == "Can you trust ancestry DNA kits?")
        #expect(sut.state.imageURL?.absoluteString == "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg")
        #expect(sut.state.scriptAttributedString != nil)
        #expect(
            sut.state.audioURL?.absoluteString == "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
        )
        
        await sut.send(.confirmErrorAlert)
        
        #expect(sut.state.fetchDataError == nil)
        #expect(sut.state.title == "Can you trust ancestry DNA kits?")
        #expect(sut.state.imageURL?.absoluteString == "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg")
        #expect(sut.state.scriptAttributedString != nil)
        #expect(
            sut.state.audioURL?.absoluteString == "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
        )
    }

}
