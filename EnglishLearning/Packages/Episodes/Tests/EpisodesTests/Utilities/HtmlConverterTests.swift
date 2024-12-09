//
//  HtmlConverterTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/23.
//

import Foundation
import Testing
@testable import Episodes

struct HtmlConverterTests {

    @Test func loadEpisodes() async throws {
        let htmlPathURL = Bundle.module.url(forResource: "Episodes", withExtension: "html")!
        let htmlString = try String(contentsOf: htmlPathURL, encoding: .utf8)
        let sut = HtmlConverter()
        let episodes = try await sut.convertHtmlToEpisodes(withHtml: htmlString)

        let firstEpisode = episodes[0]
        #expect(firstEpisode.id == "Episode 241121")
        #expect(firstEpisode.title == "The secrets to a healthy old age")
        #expect(firstEpisode.desc == "How can we stay healthy in old age?")
        #expect(firstEpisode.imageURLString == "https://ichef.bbci.co.uk/images/ic/976xn/p0k60m0v.jpg")
        #expect(
            firstEpisode.urlString == "/learningenglish/english/features/6-minute-english_2024/ep-241121"
        )
        
        let secondEpisode = episodes[1]
        #expect(secondEpisode.id == "Episode 241114")
        #expect(secondEpisode.title == "The bond between sisters")
        #expect(secondEpisode.desc == "Are the stereotypes about older and younger sisters true?")
        #expect(secondEpisode.imageURLString == "https://ichef.bbci.co.uk/images/ic/624xn/p0jyf8vv.jpg")
        #expect(
            secondEpisode.urlString == "/learningenglish/english/features/6-minute-english_2024/ep-241114"
        )
    }

}
