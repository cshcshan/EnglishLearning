//
//  File.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import Foundation
import SwiftData

@Model
final class EpisodeDetail {
    var id: String?
    var audioLink: String?
    var pdfLink: String?
    var scriptHtml: String?
    
    init(id: String?, audioLink: String?, pdfLink: String?, scriptHtml: String?) {
        self.id = id
        self.audioLink = audioLink
        self.pdfLink = pdfLink
        self.scriptHtml = scriptHtml
    }
}

extension EpisodeDetail: @unchecked Sendable {}
