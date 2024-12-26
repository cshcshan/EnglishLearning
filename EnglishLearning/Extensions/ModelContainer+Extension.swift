//
//  ModelContainer+Extension.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import Foundation
import SwiftData

extension ModelContainer {
    static func buildProd() throws -> ModelContainer {
        // TODO: to add Models after creation
        let schema = Schema([Episode.self, EpisodeDetail.self])
        let dbURL = FileManager.default.appGroup?.appendingPathComponent(Configuration.dbFileaname)
        let modelConfiguration = ModelConfiguration(schema: schema, url: dbURL!)
        return try ModelContainer(for: schema, configurations: modelConfiguration)
    }
}
