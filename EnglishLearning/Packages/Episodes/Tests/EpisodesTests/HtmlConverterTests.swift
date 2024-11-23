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
        let episodes = try sut.convertHtmlToEpisodes(withHtml: htmlString)
        let firstEpisode = episodes.first!

        #expect(firstEpisode.id == "Episode 241114")
        #expect(firstEpisode.title == "The bond between sisters")
    }

}
