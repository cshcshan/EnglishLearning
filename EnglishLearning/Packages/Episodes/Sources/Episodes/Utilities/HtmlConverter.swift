//
//  HtmlConverter.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/23.
//

import Core
import Foundation
import SwiftSoup

public protocol HtmlConvertable {
    @MainActor
    func loadEpisodes() async throws -> [Episode]
}

public actor HtmlConverter: HtmlConvertable {
    private let log: Log

    public init() {
        log = Log.network
    }

    public func loadEpisodes() async throws -> [Episode] {
        await log.add(message: "Enter HtmlConvertable.loadEpisodes()")

        guard let url = URL.episodes else {
            throw HtmlConverterError.episodesURLIncorrect
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw HtmlConverterError.episodesDataIncorrect
        }
        return try convertHtmlToEpisodes(withHtml: htmlString)
    }
    
    func convertHtmlToEpisodes(withHtml htmlString: String) throws -> [Episode] {
        let document = try SwiftSoup.parse(htmlString)

        let topElement: Episode? = try document.select(#"[data-widget-index="4"]"#).first()?.episode
        let elements = try document.select(#"[data-widget-index="5"] li.course-content-item"#)
        
        return [topElement].compactMap { $0 } + elements.compactMap { try? $0.episode }
    }
}

// MARK: - loadEpisodeDetail

extension HtmlConverter {
    
    func loadEpisodeDetail(withID id: String?, path: String?) async throws -> EpisodeDetail? {
        await log.add(message: "Enter HtmlConvertable.loadEpisodeDetail()")
        
        guard let id else {
            throw HtmlConverterError.episodeDetailIDNull
        }

        guard let path, let url = URL.episodeDomain?.appending(path: path) else {
            throw HtmlConverterError.episodeDetailURLIncorrect
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw HtmlConverterError.episodeDetailDataIncorrect
        }
        return try convertHtmlToEpisodeDetail(withID: id, htmlString: htmlString)
    }
    
    func convertHtmlToEpisodeDetail(withID id: String, htmlString: String) throws -> EpisodeDetail {
        let document = try SwiftSoup.parse(htmlString)
        return try document.episodeDetail(withID: id)
    }
}

// MARK: - SwiftSoup.Element

extension SwiftSoup.Element {

    // MARK: Episodes
    
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

// MARK: - SwiftSoup.Document

extension SwiftSoup.Document {
    
    // MARK: Episode Detail
    
    fileprivate func episodeDetail(withID id: String) throws -> EpisodeDetail {
        EpisodeDetail(
            id: id,
            audioLink: try episodeDetailAudioLink,
            pdfLink: try episodeDetailScriptPDFLink,
            scriptHtml: try episodeDetailScriptHtml
        )
    }
    
    private var episodeDetailScriptHtml: String? {
        get throws {
            guard let script = try select("div.6 > div.text").first() else { return nil }
            if let ulNode = try script.select("ul").first() {
                try script.removeChild(ulNode)
            }
            return try script.html()
        }
    }
    
    private var episodeDetailAudioLink: String? {
        get throws {
            guard let link = try select("a.bbcle-download-extension-mp3").first() else {
                return nil
            }
            return try link.attr("href").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private var episodeDetailScriptPDFLink: String? {
        get throws {
            guard let script = try select("div.6 > div.text").first() else { return nil }

            let url = try script.select("a")
                .filter { try $0.text().lowercased().contains("transcript") }
                .compactMap { try? $0.attr("href") }
                .compactMap { URL.init(string: $0) }
                .first { $0.pathExtension == "pdf" }
            return url?.absoluteString
        }
    }
}

enum HtmlConverterError: Error {
    case episodesURLIncorrect
    case episodesDataIncorrect
    case episodeDetailIDNull
    case episodeDetailURLIncorrect
    case episodeDetailDataIncorrect
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
