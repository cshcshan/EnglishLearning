//
//  EnglishLearningApp.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/11/22.
//

import SwiftUI
import Episodes

@main
struct EnglishLearningApp: App {
    @MainActor
    var body: some Scene {
        WindowGroup {
            EpisodesView(htmlConvertable: HtmlConverter(), episodeDataSource: Episode.dataSource)
        }
    }
}
