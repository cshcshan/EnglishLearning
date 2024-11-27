//
//  HtmlConverter.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/23.
//

import Foundation
import SwiftSoup

public actor HtmlConverter {
    public init() {}

    func loadEpisodes() async throws -> [Episode] {
        guard let url = URL.episodes else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let htmlString = String(data: data, encoding: .utf8) else { return [] }
        return try convertHtmlToEpisodes(withHtml: htmlString)
    }
    
    func convertHtmlToEpisodes(withHtml htmlString: String) throws -> [Episode] {
        let document = try SwiftSoup.parse(htmlString)
        let elements = try document.select("[data-widget-index=\"5\"] li.course-content-item")
        
        return elements.compactMap { try? $0.episode }
    }
}

// MARK: - SwiftSoup.Element

extension SwiftSoup.Element {
    fileprivate var episode: Episode {
        get throws {
            Episode(
                id: try episodeID,
                title: try episodeTitle,
                desc: try episodeDesc,
                date: DateFormatter.episode.date(from: try episodeDateString ?? ""),
                imageURLString: try episodeImageURLString,
                urlString: try episodeURLString
            )
        }
    }
    
    /// Episode 241114
    private var episodeID: String? {
        get throws {
            try select("div.details > h3 > b").first()?.text(trimAndNormaliseWhitespace: true)
        }
    }
    
    /// The bond between sisters
    private var episodeTitle: String? {
        get throws {
            try select("div.text > h2 > a").first()?.text(trimAndNormaliseWhitespace: true)
        }
    }
    
    /// Are the stereotypes about older and younger sisters true?
    private var episodeDesc: String? {
        get throws {
            try select("div.details > p").first()?.text(trimAndNormaliseWhitespace: true)
        }
    }
    
    /// 14 Nov 2024
    private var episodeDateString: String? {
        get throws {
            guard let episode = try select("div.details > h3 > b").first() else { return nil }

            let episodeAndDate = try select("div.details > h3").first()
            try episodeAndDate?.removeChild(episode)
            return try episodeAndDate?
                .text(trimAndNormaliseWhitespace: true)
                .replacingOccurrences(of: "/", with: "")
        }
    }
    
    /// https://ichef.bbci.co.uk/images/ic/624xn/p0jyf8vv.jpg
    private var episodeImageURLString: String? {
        get throws {
            try select("img").first()?.attr("src").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// /learningenglish/english/features/6-minute-english_2024/ep-241114
    private var episodeURLString: String? {
        get throws {
            try select("div.text > h2 > a").first()?.attr("href").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - DateFormatter

extension DateFormatter {
    fileprivate static var episode: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.locale = Locale(identifier: "en")
        return dateFormatter
    }
}
