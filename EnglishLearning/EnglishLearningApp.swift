//
//  EnglishLearningApp.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/11/22.
//

import Core
import Episodes
import SwiftData
import SwiftUI

@main
struct EnglishLearningApp: App {
    private let dataSource: DataSource
    
    @MainActor
    var body: some Scene {
        WindowGroup {
            EpisodesView(
                htmlConvertable: HtmlConverter(),
                dataSource: dataSource
            )
        }
        .modelContainer(dataSource.modelContainer)
    }
    
    init() {
        do {
            // TODO: to add Models after creation
            let schema = Schema([Episode.self, EpisodeDetail.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            let modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            
            self.dataSource = try DataSource(with: modelContainer)
        } catch {
            fatalError()
        }
        
        printSandbox()
    }
    
    private func printSandbox() {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        print("Library \(libraryURL?.absoluteString ?? "")")
        
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Configuration.groupID
        )
        print("App Group \(appGroupURL?.absoluteString ?? "")")
    }
}
