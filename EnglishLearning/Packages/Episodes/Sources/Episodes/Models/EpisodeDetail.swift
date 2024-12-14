//
//  File.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import Core
import Foundation
import SwiftData

@Model
public final class EpisodeDetail {
    public var id: String?
    public var audioLink: String?
    public var pdfLink: String?
    public var scriptHtml: String?
    
    public init(id: String?, audioLink: String? = nil, pdfLink: String? = nil, scriptHtml: String? = nil) {
        self.id = id
        self.audioLink = audioLink
        self.pdfLink = pdfLink
        self.scriptHtml = scriptHtml
    }
}

extension EpisodeDetail {
    var audioURL: URL? {
        URL(string: audioLink ?? "")
    }
}

extension EpisodeDetail: @unchecked Sendable {}

extension EpisodeDetail {
    @MainActor
    static let dataSource: DataSource? = {
        do {
            return try DataSource(for: EpisodeDetail.self, isStoredInMemoryOnly: false)
        } catch {
            // TODO: Add error message to Log later since it cause a compile error
            // `Default argument cannot be both main actor-isolated and actor-isolated`
//            Task { Log.data.add(error: error) }
            return nil
        }
    }()
}
